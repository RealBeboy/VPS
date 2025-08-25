#!/usr/bin/env bash
# Secure SFTP setup (container-friendly; uses `service ssh restart`)
# Usage (as root): SFTP_USER=sftpuser SFTP_PASS='testpass123' SFTP_PORT=2222 bash setup_sftp.sh

set -euo pipefail

# -------- Config (env-overridable) --------
SFTP_USER="${SFTP_USER:-sftpuser}"
SFTP_PASS="${SFTP_PASS:-testpass123}"
SFTP_GROUP="${SFTP_GROUP:-sftpusers}"
SFTP_PORT="${SFTP_PORT:-2222}"
SFTP_HOME="/home/${SFTP_USER}"
UPLOAD_DIR="${SFTP_HOME}/uploads"
SSHD_CONFIG="/etc/ssh/sshd_config"
BLOCK_START="# BEGIN SFTP-BLOCK (managed)"
BLOCK_END="# END SFTP-BLOCK (managed)"
NOLOGIN_BIN="/usr/sbin/nologin"

# -------- Helpers --------
need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root (use sudo)." >&2
    exit 1
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

restart_ssh() {
  # Container-safe restart (no systemctl)
  service ssh restart
}

ensure_nologin() {
  if [[ ! -x "${NOLOGIN_BIN}" ]]; then
    # Fallback path on some distros
    if [[ -x "/sbin/nologin" ]]; then
      NOLOGIN_BIN="/sbin/nologin"
    else
      # Provide a dummy nologin if truly missing (rare)
      printf '#!/bin/sh\nexit 1\n' > /usr/sbin/nologin
      chmod +x /usr/sbin/nologin
      NOLOGIN_BIN="/usr/sbin/nologin"
    fi
  fi
}

# -------- Start --------
need_root

echo "=== Automated SFTP Setup Script ==="

# Ensure OpenSSH server exists (Debian/Ubuntu)
if ! have_cmd sshd; then
  if have_cmd apt-get; then
    echo "Installing openssh-server..."
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
  else
    echo "OpenSSH server not found. Install it for your distro, then re-run." >&2
    exit 1
  fi
fi

# Fix noisy sudo hostname issue (optional, harmless)
if ! grep -q "$(hostname)" /etc/hosts; then
  echo "127.0.1.1 $(hostname)" >> /etc/hosts || true
fi

# Make sure nologin exists
ensure_nologin

# Create group if needed
if ! getent group "${SFTP_GROUP}" >/dev/null; then
  groupadd "${SFTP_GROUP}"
fi

# Create user if needed (no shell)
if ! id -u "${SFTP_USER}" >/dev/null 2>&1; then
  useradd -m -d "${SFTP_HOME}" -s "${NOLOGIN_BIN}" "${SFTP_USER}"
fi

# Ensure user in sftpusers group and with nologin shell
usermod -a -G "${SFTP_GROUP}" "${SFTP_USER}"
usermod -s "${NOLOGIN_BIN}" "${SFTP_USER}"

# Set/Reset password
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd

# Prepare chroot-friendly directory permissions
mkdir -p "${UPLOAD_DIR}"
chown root:root "${SFTP_HOME}"
chmod 755 "${SFTP_HOME}"

chown "${SFTP_USER}:${SFTP_USER}" "${UPLOAD_DIR}"
chmod 775 "${UPLOAD_DIR}"

# Backup sshd_config once per run
if [[ ! -f "${SSHD_CONFIG}.bak" ]]; then
  cp -a "${SSHD_CONFIG}" "${SSHD_CONFIG}.bak"
fi

# Ensure Subsystem uses internal-sftp (single line)
if grep -qiE '^\s*Subsystem\s+sftp' "${SSHD_CONFIG}"; then
  sed -i -E 's|^\s*Subsystem\s+sftp.*$|Subsystem sftp internal-sftp|' "${SSHD_CONFIG}"
else
  echo "Subsystem sftp internal-sftp" >> "${SSHD_CONFIG}"
fi

# Ensure both 22 and custom SFTP_PORT are present (idempotent)
if ! grep -qE '^\s*Port\s+22(\s|$)' "${SSHD_CONFIG}"; then
  echo "Port 22" >> "${SSHD_CONFIG}"
fi
if ! grep -qE "^\s*Port\s+${SFTP_PORT}\b" "${SSHD_CONFIG}"; then
  echo "Port ${SFTP_PORT}" >> "${SSHD_CONFIG}"
fi

# Remove any previous managed block, then add fresh one (append at end)
sed -i "/${BLOCK_START}/,/${BLOCK_END}/d" "${SSHD_CONFIG}"

cat >> "${SSHD_CONFIG}" <<EOF

${BLOCK_START}
# Restrict members of ${SFTP_GROUP} to SFTP-only, chrooted to their home
Match Group ${SFTP_GROUP}
    ChrootDirectory %h
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTCPForwarding no
    PasswordAuthentication yes
${BLOCK_END}
EOF

# Optional: open firewall if UFW active (containers usually don't use ufw)
if have_cmd ufw && ufw status | grep -q "Status: active"; then
  ufw allow "${SFTP_PORT}"/tcp || true
fi

# Restart SSH to apply changes (container-safe)
echo "Restarting SSH service..."
restart_ssh

# Quick config sanity output
echo
echo "=== SFTP Setup Completed ==="
echo "• User: ${SFTP_USER}"
echo "• Password: ${SFTP_PASS}"
echo "• Chroot: ${SFTP_HOME} (root:root, 755)"
echo "• Upload dir: ${UPLOAD_DIR} (${SFTP_USER}:${SFTP_USER}, 775)"
echo "• Ports: 22 and ${SFTP_PORT}"
echo
echo "Connect manually with:"
echo "  sftp -P ${SFTP_PORT} ${SFTP_USER}@localhost"
echo "  (then: cd uploads; put <file>)"

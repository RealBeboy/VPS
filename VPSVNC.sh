#!/bin/bash
set -e

# --- User Input Section ---
# Ask for VPS code
read -p "Enter your VPS code: " vpscode

# Ask for VNC password without showing it on the screen
read -sp "Enter the VNC Password to set: " vnc_password
echo # Adds a newline for clean formatting


# --- Detect the real user running the script ---
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER=$(whoami)
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)


# --- System Configuration ---
# Correctly apply VPS code to /etc/hosts
echo "--- Configuring /etc/hosts... ---"
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1       localhost ${vpscode}
::1     localhost ip6-localhost ip6-loopback
fe00::  ip6-localnet
ff00::  ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.17.0.2      e91e22096dd8
EOF


# --- Pre-seed Debconf Selections for Automated Installation ---
echo "--- Pre-configuring installer settings... ---"
echo "keyboard-configuration keyboard-configuration/xkb-keymap select us" | sudo debconf-set-selections
echo "lightdm shared/default_display_manager select lightdm" | sudo debconf-set-selections


# --- Package Installation ---
echo "--- Updating package list and installing software... ---"
sudo add-apt-repository universe -y
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    xfce4 \
    lightdm \
    xfce4-goodies \
    novnc \
    python3-websockify \
    python3-numpy \
    tigervnc-standalone-server \
    htop nano neofetch \
    firefox


# --- VNC Password and Server Configuration (Guaranteed Non-Interactive) ---
echo "--- Configuring VNC server for user '$REAL_USER'... ---"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.vnc"
echo "$vnc_password" | sudo -u "$REAL_USER" vncpasswd -f > "$USER_HOME/.vnc/passwd"
sudo -u "$REAL_USER" chmod 600 "$USER_HOME/.vnc/passwd"

# Create the more robust xstartup file to launch XFCE
sudo -u "$REAL_USER" tee "$USER_HOME/.vnc/xstartup" > /dev/null <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
sudo -u "$REAL_USER" chmod +x "$USER_HOME/.vnc/xstartup"


# --- Generate SSL Certificate for noVNC ---
echo "--- Generating SSL certificate... ---"
sudo -u "$REAL_USER" openssl req -x509 -nodes -newkey rsa:3072 \
    -keyout "$USER_HOME/novnc.pem" -out "$USER_HOME/novnc.pem" -days 3650 \
    -subj "/C=US/ST=None/L=None/O=NoVNC/CN=localhost"


# --- Start Services (as the correct user) ---
echo "--- Starting VNC and noVNC services... ---"
# TigerVNC needs the '-localhost no' flag to be accessible over the network
sudo -u "$REAL_USER" vncserver :1 -localhost no

sudo -u "$REAL_USER" websockify -D --web=/usr/share/novnc/ --cert="$USER_HOME/novnc.pem" 6080 localhost:5901


# --- Final Output ---
# Display system info (run as the user for correct theme/shell info)
sudo -u "$REAL_USER" neofetch

# Output access info
echo ""
echo "========================================================================="
echo "✅ Setup complete! Access your instance via the URLs below:"
echo ""
echo "   noVNC Link: https://${vpscode}-6080.csb.app/vnc.html"
echo "   Agent Link: https://agent.blackbox.ai/?sandbox=${vpscode}"
echo ""
echo "   Your VNC password has been set for user '$REAL_USER'."
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."
echo "========================================================================="

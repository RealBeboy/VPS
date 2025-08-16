#!/bin/bash
set -e

# --- User Input Section ---
# Ask for VPS code
read -p "Enter your VPS code: " vpscode

# Ask for VNC password without showing it on the screen
read -sp "Enter the VNC Password to set: " vnc_password
echo # Adds a newline for clean formatting


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
# 1. Set Keyboard Layout to 'English (US)'
echo "keyboard-configuration keyboard-configuration/xkb-keymap select us" | sudo debconf-set-selections
# 2. Set the default display manager to 'lightdm'
echo "lightdm shared/default_display_manager select lightdm" | sudo debconf-set-selections


# --- Package Installation ---
echo "--- Updating package list and installing software... ---"
# Ensure the universe repository is enabled for desktop packages
sudo add-apt-repository universe -y
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    xfce4 \
    lightdm \
    xfce4-goodies \
    novnc \
    python3-websockify \
    python3-numpy \
    tightvncserver \
    htop nano neofetch \
    firefox


# --- VNC Password and Server Configuration ---
echo "--- Configuring VNC server automatically... ---"
# Automatically set the VNC password from user input
mkdir -p ~/.vnc
echo -e "${vnc_password}\n${vnc_password}\nn" | vncpasswd

# Backup and create new xstartup file to launch XFCE
[ -f ~/.vnc/xstartup ] && mv ~/.vnc/xstartup ~/.vnc/xstartup.bak
cat <<EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup


# --- Generate SSL Certificate for noVNC ---
echo "--- Generating SSL certificate... ---"
openssl req -x509 -nodes -newkey rsa:3072 \
    -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 \
    -subj "/C=US/ST=None/L=None/O=NoVNC/CN=localhost"


# --- Start Services ---
echo "--- Starting VNC and noVNC services... ---"
# Start VNC server on display :1
vncserver :1

# Start noVNC (websockify) in the background
websockify -D --web=/usr/share/novnc/ --cert=\$HOME/novnc.pem 6080 localhost:5901


# --- Final Output ---
# Display system info
neofetch

# Output access info
echo ""
echo "========================================================================="
echo "✅ Setup complete! Access your instance via the URLs below:"
echo ""
echo "   noVNC Link: https://${vpscode}-6080.csb.app/vnc.html"
echo "   Agent Link: https://agent.blackbox.ai/?sandbox=${vpscode}"
echo ""
echo "   Your VNC password has been set."
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."
echo "========================================================================="

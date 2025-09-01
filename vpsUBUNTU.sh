#!/bin/bash
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/index.html
# Ask for VPS code
read -p "Enter your VPS code: " vpscode

# Correctly apply VPS code to /etc/hosts
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1       localhost ${vpscode}
::1     localhost ip6-localhost ip6-loopback
fe00::  ip6-localnet
ff00::  ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Update system and install the stable MATE Desktop Environment
echo "--- Installing packages, this may take a few minutes... ---"
sudo apt-get update && sudo apt-get install -y \
    ubuntu-mate-desktop \
    novnc \
    python3-websockify \
    python3-numpy \
    tightvncserver \
    htop nano neofetch \
    firefox

# Generate SSL certificate for noVNC
echo "--- Generating SSL certificate... ---"
openssl req -x509 -nodes -newkey rsa:3072 \
    -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 \
    -subj "/C=US/ST=None/L=None/O=NoVNC/CN=localhost"

# Initialize VNC config and set a password
# You will be prompted to enter a VNC password here
echo "--- Initializing VNC Server, please set your password ---"
vncserver :1
vncserver -kill :1

# Backup and create new xstartup file for MATE
[ -f ~/.vnc/xstartup ] && mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

# Create a reliable xstartup script for the MATE desktop
cat <<EOF > ~/.vnc/xstartup
#!/bin/sh
export XDG_SESSION_TYPE=x11
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
mate-session &
EOF

# Make the new xstartup script executable
chmod +x ~/.vnc/xstartup

# Start VNC server with a common resolution
# The -localhost flag is a security best practice
echo "--- Starting VNC server... ---"
vncserver -geometry 1600x900 -localhost :1

# Start noVNC (websockify) in the background
echo "--- Starting noVNC service... ---"
websockify -D --web=/usr/share/novnc/ --cert=\$HOME/novnc.pem 6080 localhost:5901

# Display system info
neofetch

# Output access info
echo "✅ Setup complete! Access your working Ubuntu desktop at https://${vpscode}-6080.csb.app/vnc.html"
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."
python -m http.server 8080

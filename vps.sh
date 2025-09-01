#!/bin/bash

curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/main/index.html
# Ask for VPS code
read -p "Enter your VPS code: " vpscode
read -p "Enter your site 1 code: " site1
read -p "Enter your site 2 code: " site2

# Correctly apply VPS code to /etc/hosts
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1       localhost ${vpscode}
::1     localhost ip6-localhost ip6-loopback
fe00::  ip6-localnet
ff00::  ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.17.0.2      e91e22096dd8
EOF

# Install required packages including Firefox
sudo apt update && sudo apt install -y \
    xfce4 xfce4-goodies \
    novnc \
    python3-websockify \
    python3-numpy \
    tightvncserver \
    htop nano neofetch \
    firefox

# Generate SSL certificate for noVNC
openssl req -x509 -nodes -newkey rsa:3072 \
    -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 \
    -subj "/C=US/ST=None/L=None/O=NoVNC/CN=localhost"

# Initialize VNC config
vncserver
vncserver -kill :1

# Backup and create new xstartup
[ -f ~/.vnc/xstartup ] && mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

cat <<EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOF

chmod +x ~/.vnc/xstartup

# Start VNC server
vncserver

# Start noVNC (websockify) in background
websockify -D --web=/usr/share/novnc/ --cert=\$HOME/novnc.pem 6080 localhost:5901

# Display system info
neofetch

sudo tee 24.sh > /dev/null <<EOF
#!/bin/bash

# Derived websites from your codes
SITE1="https://agent.blackbox.ai/?sandbox=${site1}"
SITE1web="https://${site1}-8080.csb.app/"
SITE2="https://agent.blackbox.ai/?sandbox=${site2}"
SITE2web="https://${site2}-8080.csb.app/"

# Customize window size and position
WIDTH=1500
HEIGHT=300
POSX=100
POSY=100

# Start Firefox in a new window with all tabs
firefox --new-window "\$SITE1" "\$SITE1web" "\$SITE2" "\$SITE2web" \
  --width "\$WIDTH" --height "\$HEIGHT" --new-instance &

# Move/resize window (X11). In VNC this works fine.
for i in {1..10}; do
  if wmctrl -r "Mozilla Firefox" -e 0,"\$POSX","\$POSY","\$WIDTH","\$HEIGHT" 2>/dev/null; then
    break
  fi
  sleep 0.5
done
EOF

sudo chmod +x 24.sh

# Output access info
echo "✅ Setup complete! Access noVNC at https://${vpscode}-6080.csb.app/vnc.html"
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."

#!/bin/bash
# backup
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F)

sudo apt-get install wmctrl

# replace http -> https for the main Ubuntu mirrors
sudo sed -i -E 's#http://(security\.ubuntu\.com|archive\.ubuntu\.com)#https://\1#g' /etc/apt/sources.list

# (optional) do the same for any extra lists
sudo grep -RIl 'http://security\.ubuntu\.com|http://archive\.ubuntu\.com' /etc/apt/sources.list.d 2>/dev/null | \
  xargs -r sudo sed -i -E 's#http://(security\.ubuntu\.com|archive\.ubuntu\.com)#https://\1#g'

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

# Install required packages including Firefox and wmctrl
sudo apt update && sudo apt install -y \
    xfce4 xfce4-goodies \
    novnc \
    python3-websockify \
    python3-numpy \
    tightvncserver \
    htop nano neofetch \
    firefox \
    wmctrl

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
vncserver -geometry 1280x720

# Start noVNC (websockify) in background
websockify -D --web=/usr/share/novnc/ --cert=\$HOME/novnc.pem 6080 localhost:5901

# Display system info
neofetch

# Create the 24.sh script with the new 2x2 grid logic
# The ${site1} and ${site2} variables are expanded here, embedding them into the new script.
# Other variables are escaped with '\' so they are interpreted when 24.sh is run.
sudo tee 24.sh > /dev/null <<EOF
#!/bin/bash

# This script opens multiple Firefox windows, each with a size of 640x360.
# It uses Firefox's native command-line arguments.

# --- Configuration ---
# URLs are set by the parent script that generated this file.
URL1="https://agent.blackbox.ai/?sandbox=${site1}"
URL2="https://${site1}-8080.csb.app/"
URL3="https://agent.blackbox.ai/?sandbox=${site2}"
URL4="https://${site2}-8080.csb.app/"

# Window dimensions
WIDTH=640
HEIGHT=360

# --- Script Logic ---
# A helper function to launch a URL in a new window with a specified size.
launch_window() {
  local url="\$1"
  echo "Opening \$url in a new \${WIDTH}x\${HEIGHT} window..."

  # --new-window: Opens the URL in a new Firefox window.
  # --width: Sets the initial width of the window.
  # --height: Sets the initial height of the window.
  # &: Runs the command in the background so the script can continue.
  firefox --new-window "\$url" --width "\$WIDTH" --height "\$HEIGHT" &
}

# --- Execution ---
# Launch each configured window sequentially.
# A small delay is added between launches to ensure they open reliably.
launch_window "\$URL1"
sleep 1
launch_window "\$URL2"
sleep 1
launch_window "\$URL3"
sleep 1
launch_window "\$URL4"

echo "Script finished."
EOF

sudo chmod +x 24.sh

# Output access info
echo "✅ Setup complete! Access noVNC at https://${vpscode}-6080.csb.app/vnc.html?password=beboy123"
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."
echo "👉 Run './24.sh' inside the VNC session to launch the tiled Firefox windows."

python3 -m http.server 8080

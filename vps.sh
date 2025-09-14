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

# This script opens multiple Firefox windows and positions them in a 2x2 grid
# optimized for a 1280x720 display.
# It requires 'wmctrl' to be installed.

# --- Configuration ---
# Geometry is defined for a 1280x720 screen, splitting it into four quadrants.
# Each window will be 640px wide and 360px tall.
# The format for GEOMETRY is: gravity,x_position,y_position,width,height

# -- Window 1 (Top-Left) --
URL1="https://agent.blackbox.ai/?sandbox=${site1}"
GEOMETRY1="0,0,0,640,360"

# -- Window 2 (Top-Right) --
URL2="https://${site1}-8080.csb.app/"
GEOMETRY2="0,640,0,640,360"

# -- Window 3 (Bottom-Left) --
URL3="https://agent.blackbox.ai/?sandbox=${site2}"
GEOMETRY3="0,0,360,640,360"

# -- Window 4 (Bottom-Right) --
URL4="https://${site2}-8080.csb.app/"
GEOMETRY4="0,640,360,640,360"


# --- Script Logic ---
# A helper function to launch a URL in a new window and then position it.
# It works by targeting the most recently created Firefox window.
launch_and_position() {
  local url="\$1"
  local geometry="\$2"
  # This targets a generic Firefox window. The sleep command helps ensure we get the newest one.
  local window_title="Mozilla Firefox"

  echo "Opening \$url in a new window..."
  # Open the URL in a new window and send the process to the background
  firefox --new-window "\$url" &

  # Give the browser a moment to create the window before we try to manage it.
  sleep 2

  echo "Positioning window for \$url..."
  # Loop for a few seconds, repeatedly trying to position the new window.
  for i in {1..10}; do
    # -r: Selects a window by its name. wmctrl will act on the topmost one.
    # -e: Specifies the new geometry (gravity,x,y,width,height).
    if wmctrl -r "\$window_title" -e "\$geometry" 2>/dev/null; then
      echo "Window positioned successfully."
      break # Exit the loop on success
    fi

    # If it fails on the last attempt, print a warning.
    if [ "\$i" -eq 10 ]; then
      echo "Warning: Could not position the window for \$url."
    fi
    sleep 0.5 # Wait before retrying
  done
}

# --- Execution ---
# Launch and position each configured window sequentially.
launch_and_position "\$URL1" "\$GEOMETRY1"
launch_and_position "\$URL2" "\$GEOMETRY2"
launch_and_position "\$URL3" "\$GEOMETRY3"
launch_and_position "\$URL4" "\$GEOMETRY4"

echo "Script finished."
EOF

sudo chmod +x 24.sh

# Output access info
echo "✅ Setup complete! Access noVNC at https://${vpscode}-6080.csb.app/vnc.html?password=beboy123"
echo "📌 VPS code '${vpscode}' has been applied to /etc/hosts."
echo "👉 Run './24.sh' inside the VNC session to launch the tiled Firefox windows."

python3 -m http.server 8080

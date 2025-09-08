#!/bin/bash
set -e

# --- Fetch helper files (optional assets you referenced) ---
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/main/index.html

# --- Ask for codes ---
read -p "Enter your VPS code: " vpscode
read -p "Enter your site 1 code: " site1
read -p "Enter your site 2 code: " site2

# --- Apply VPS code to /etc/hosts (overwrites host file!) ---
# NOTE: This replaces /etc/hosts. If you prefer to append, see the commented block below.
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1       localhost ${vpscode}
::1     localhost ip6-localhost ip6-loopback
fe00::  ip6-localnet
ff00::1 ip6-allnodes
ff00::2 ip6-allrouters
EOF

# If you'd rather APPEND instead of overwrite, use this instead:
# echo "127.0.0.1 ${vpscode}" | sudo tee -a /etc/hosts >/dev/null

# --- Install packages ---
echo "--- Installing packages, this may take a few minutes... ---"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ubuntu-mate-desktop \
  novnc \
  python3-websockify \
  python3-numpy \
  tightvncserver \
  wmctrl \
  htop nano neofetch \
  firefox

# --- Generate SSL cert for noVNC ---
echo "--- Generating SSL certificate... ---"
openssl req -x509 -nodes -newkey rsa:3072 \
  -keyout "$HOME/novnc.pem" -out "$HOME/novnc.pem" -days 3650 \
  -subj "/C=US/ST=None/L=None/O=NoVNC/CN=localhost"

# --- Initialize VNC config and set a password (you will be prompted) ---
echo "--- Initializing VNC Server, please set your password ---"
vncserver :1
vncserver -kill :1

# --- Configure VNC to start MATE session ---
[ -f "$HOME/.vnc/xstartup" ] && mv "$HOME/.vnc/xstartup" "$HOME/.vnc/xstartup.bak"
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
export XDG_SESSION_TYPE=x11
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
mate-session &
EOF
chmod +x "$HOME/.vnc/xstartup"

# --- Start VNC server ---
echo "--- Starting VNC server... ---"
vncserver -geometry 1600x900 -localhost :1

# --- Start noVNC (websockify) in the background ---
echo "--- Starting noVNC service... ---"
websockify -D --web=/usr/share/novnc/ --cert="$HOME/novnc.pem" 6080 localhost:5901

# --- Show system info ---
neofetch || true

# --- Create the windowed Firefox launcher with your site codes baked in ---
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

# --- Output access info ---
echo "✅ Setup complete!"
echo "🌐 noVNC:  https://${vpscode}-6080.csb.app/vnc.html?password=beboy123"
echo "🧪 Local web: serving current dir on :8080 (index.html present)"
echo "▶️  To open your sites in a window: ./24.sh"

# --- Serve the current directory (index.html etc.) on port 8080 ---
python3 -m http.server 8080

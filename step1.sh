read -p "Enter your VPS code: " vpscode

sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F)

# replace http -> https for the main Ubuntu mirrors
sudo sed -i -E 's#http://(security\.ubuntu\.com|archive\.ubuntu\.com)#https://\1#g' /etc/apt/sources.list

# (optional) do the same for any extra lists
sudo grep -RIl 'http://security\.ubuntu\.com|http://archive\.ubuntu\.com' /etc/apt/sources.list.d 2>/dev/null | \
  xargs -r sudo sed -i -E 's#http://(security\.ubuntu\.com|archive\.ubuntu\.com)#https://\1#g'

# Correctly apply VPS code to /etc/hosts
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "1.1.1.1"]
}
EOF

sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1       localhost ${vpscode}
::1     localhost ip6-localhost ip6-loopback
fe00::  ip6-localnet
ff00::  ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/index.html
mkdir windows
cd windows
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker_compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/playit.yml
docker compose -f docker_compose.yml up -d
docker compose logs windows
echo "✅ Setup complete! Access your Windows desktop at https://${vpscode}-8006.csb.app"
cd /project/sandbox/user-workspace
python -m http.server 8080

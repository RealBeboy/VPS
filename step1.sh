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

curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/index.html
mkdir windows
cd windows
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker_compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker-compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/playit.yml
docker compose -f docker_compose.yml up -d
docker compose logs windows
echo "✅ Setup complete! Access your Windows desktop at https://${vpscode}-8006.csb.app"
cd /project/sandbox/user-workspace
python -m http.server 8080

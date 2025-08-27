curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
sudo apt update
sudo apt install playit -y
playit
docker compose down --remove-orphans
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/getsecretkey.sh
bash getsecretkey.sh
docker compose up -d
docker compose logs -f playit

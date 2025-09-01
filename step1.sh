curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/24.py
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/index.html
mkdir windows
cd windows
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker_compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker-compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/playit.yml
docker compose -f docker_compose.yml up -d
docker compose logs windows

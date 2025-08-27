# VPS
free vps method with vnc
415464440658xxxx
xfce
```
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/vps.sh
bash vps.sh

```
vps ubuntu
```
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/vpsUBUNTU.sh
bash vpsUBUNTU.sh

```
setup sftp
```
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/setup_sftp.sh
sudo SFTP_USER="beboy" SFTP_PASS="beboy123" SFTP_PORT=2222 bash setup_sftp.sh

```
windows 10

Step 1
```
mkdir windows
cd windows
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/docker_compose.yml
curl -s -O https://raw.githubusercontent.com/RealBeboy/VPS/refs/heads/main/playit.yml
docker compose up -d
docker compose logs windows

```
Step 2
install play it and get the secret key run it after connecting ctrl+c
port forward tcp 3389 then wwait the installation mga 1 hour pana or 30 minutes ambot
```
curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
sudo apt update
sudo apt install playit
playit
cat ~/.config/playit_gg/playit.toml
cd /project/sandbox/user-workspace/windows
nano docker-compose.yml
docker compose down --remove-orphans
docker compose up -d
docker compose logs -f windows

```

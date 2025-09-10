#!/bin/bash


while true; do
    read -p "Do you have the playit key? (yes create docker-compose.yml / no get secret key): " answer
    
    if [[ "$answer" == "yes" || "$answer" == "y" || "$answer" == "YES" ]]; then
    read -p "Enter your secret key code: " secretkey
        sudo tee /project/sandbox/user-workspace/windows/docker-compose.yml > /dev/null <<EOF
version: "3.9"

services:
  windows:
    image: dockurr/windows
    container_name: windows
    ports:
      - "127.0.0.1:3389:3389"   # bind ONLY to host localhost
    environment:
      VERSION: "10l"
      KVM: "N"
      VNCPASS: "beboy123"
      RAM_SIZE: "6G"
      CPU_CORES: "6"
      DISK_SIZE: "14G"
      DISK_FMT: "raw"
      DISK_PREALLOC: "Y"
    volumes:
      - windows_data:/storage
    restart: unless-stopped
    stop_grace_period: 2m

  playit:
    image: ghcr.io/playit-cloud/playit-agent:latest
    container_name: playit
    environment:
      SECRET_KEY: "${secretkey}"
    # Crucial: use host network so 127.0.0.1 = host
    network_mode: "host"
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "1"

volumes:
  windows_data: {}

EOF
        echo "✅ docker-compose.yml created at /project/sandbox/user-workspace/windows/"
        break
    else
        cat ~/.config/playit_gg/playit.toml
    fi
done

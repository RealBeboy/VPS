#!/bin/bash


while true; do
    read -p "Do you have the playit key? (yes create docker-compose.yml / no get secret key): " answer
    
    if [[ "$answer" == "yes" || "$answer" == "y" || "$answer" == "YES" ]]; then
    read -p "Enter your secret key code: " secretkey
        sudo tee /project/sandbox/user-workspace/windows/docker-compose.yml > /dev/null <<EOF
version: "3.9"

networks:
  appnet: {}

volumes:
  windows_data:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: size=14g,uid=0,gid=0,mode=0755

services:
  windows:
    image: dockurr/windows
    container_name: windows
    ports:
      - "3389:3389"       # RDP
      - "5900:5900"  
    environment:
      VERSION: "10l"
      KVM: "N"
      VNCPASS: "beboy123"
      RAM_SIZE: "6G"
      CPU_CORES: "6"
      DISK_SIZE: "14G"
      DISK_FMT: "raw"
      USERNAME: "BeboyRDP"
      PASSWORD: "beboy123"
    volumes:
      - windows_data:/storage
    restart: unless-stopped
    stop_grace_period: 2m
    networks:
      - appnet

  playit:
    image: ghcr.io/playit-cloud/playit-agent:latest
    container_name: playit
    environment:
      SECRET_KEY: "${secretkey}"
    depends_on:
      - windows
    restart: unless-stopped
    networks:
      - appnet
EOF
        echo "✅ docker-compose.yml created at /project/sandbox/user-workspace/windows/"
        break
    else
        cat ~/.config/playit_gg/playit.toml
    fi
done

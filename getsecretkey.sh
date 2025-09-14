#!/bin/bash


while true; do
    read -p "Do you have the playit key? (yes create docker-compose.yml / no get secret key): " answer
    
    if [[ "$answer" == "yes" || "$answer" == "y" || "$answer" == "YES" ]]; then
    read -p "Enter your secret key code: " secretkey
        sudo tee /project/sandbox/user-workspace/windows/docker-compose.yml > /dev/null <<EOF
version: "3.9"

networks:
  appnet: {}

# This volume will now be persistent and stored on your disk.
volumes:
  windows_data: {}

services:
  windows:
    image: dockurr/windows
    container_name: windows
    ports:
      - "3389:3389"      # RDP
      - "5900:5900"
      - "8006:8006"
    environment:
      # This tells the container to create a 14GB virtual disk.
      VERSION: "10l"
      KVM: "N"
      VNCPASS: "beboy123"
      RAM_SIZE: "6G"
      CPU_CORES: "6"
      DISK_SIZE: "14G"
      USERNAME: "BeboyRDP"
      PASSWORD: "beboy123"
    volumes:
      # This links the container's storage to the persistent volume.
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

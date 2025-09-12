#!/bin/bash


while true; do
    read -p "Do you have the playit key? (yes create docker-compose.yml / no get secret key): " answer
    
    if [[ "$answer" == "yes" || "$answer" == "y" || "$answer" == "YES" ]]; then
    read -p "Enter your secret key code: " secretkey
        sudo tee /project/sandbox/user-workspace/windows/docker-compose.yml > /dev/null <<EOF
version: "3.9"

networks:
  appnet: {}

services:
  windows:
    image: dockurr/windows
    container_name: windows
    ports:
      - "3389:3389"
    environment:
      # This tells the Windows VM inside the container to use 6GB of RAM.
      RAM_SIZE: "6G"
      
      # Other VM settings
      VERSION: "10l"
      KVM: "N"
      VNCPASS: "beboy123"
      CPU_CORES: "6"
      DISK_SIZE: "14G"
      DISK_FMT: "raw"
      DISK_PREALLOC: "Y"
      USERNAME: "BeboyRDP"
      PASSWORD: "beboy123"
      
    deploy:
      resources:
        limits:
          # The container can use up to 8GB of physical RAM...
          memory: 8G
          # ...and a total of 12GB (8GB RAM + 4GB Swap) before being killed.
          memory_swap: 12G
          
    volumes:
      - windows_data:/storage
    restart: unless-stopped
    # Gives the Windows OS 2 minutes to shut down gracefully.
    stop_grace_period: 2m
    networks: [appnet]
    # Prevents log files from growing indefinitely and filling the disk.
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "1"

  playit:
    image: ghcr.io/playit-cloud/playit-agent:latest
    container_name: playit
    environment:
      # Make sure you have a .env file in the same directory
      # with the line: secretkey=YOUR_ACTUAL_SECRET_KEY
      SECRET_KEY: "${secretkey}"
    # Shares the network of the 'windows' service.
    network_mode: "service:windows"
    depends_on:
      - windows
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "1"

volumes:
  # Defines the persistent volume for the Windows virtual disk.
  windows_data: {}

EOF
        echo "✅ docker-compose.yml created at /project/sandbox/user-workspace/windows/"
        break
    else
        cat ~/.config/playit_gg/playit.toml
    fi
done

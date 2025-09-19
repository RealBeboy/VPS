#!/bin/bash

while true; do
    read -p "Do you have the ngrok authtoken? (yes create docker-compose.yml / no show how to get token): " answer

    if [[ "$answer" =~ ^(yes|y|YES|Y)$ ]]; then
        read -p "Enter your ngrok authtoken: " authtoken
        read -p "Enter ngrok region (us, eu, ap, au, in, jp, sa) [default: ap]: " ngregion
        ngregion=${ngregion:-ap}

        # ngrok config: single TCP tunnel to 172.19.0.2:5900
        sudo tee /project/sandbox/user-workspace/windows/ngrok.yml > /dev/null <<EOF
version: "3"
region: "${ngregion}"
tunnels:
  vnc5900:
    proto: tcp
    addr: 172.19.0.2:5900
EOF

        # docker-compose: windows block unchanged; ngrok sidecar reads ngrok.yml
        sudo tee /project/sandbox/user-workspace/windows/docker-compose.yml > /dev/null <<EOF
version: "3.9"

networks:
  appnet: {}

volumes:
  windows_data: {}

services:
  windows:
    image: dockurr/windows
    container_name: windows
    # No host port publishing; ngrok connects over Docker network
    environment:
      VERSION: "8e"
      KVM: "N"
      VNCPASS: "beboy123"
      RAM_SIZE: "6G"
      CPU_CORES: "6"
      USERNAME: "BeboyRDP"
      PASSWORD: "beboy123"
    volumes:
      - windows_data:/storage
    restart: unless-stopped
    stop_grace_period: 2m
    networks:
      - appnet

  ngrok:
    image: ngrok/ngrok:latest
    container_name: ngrok
    environment:
      NGROK_AUTHTOKEN: "${authtoken}"
    depends_on:
      - windows
    command: ["start", "--all", "--config", "/etc/ngrok.yml"]
    volumes:
      - /project/sandbox/user-workspace/windows/ngrok.yml:/etc/ngrok.yml:ro
    restart: unless-stopped
    networks:
      - appnet
EOF

        echo "✅ Created docker-compose.yml and ngrok.yml at /project/sandbox/user-workspace/windows/"
        echo "Run:"
        echo "  cd /project/sandbox/user-workspace/windows && docker compose up -d"
        echo "Get the TCP address:"
        echo "  docker logs -f ngrok   # look for vnc5900 -> tcp://0.tcp.ngrok.io:xxxxx"
        echo "  done"
        break
    else
        echo "➡️  Get your ngrok authtoken: https://dashboard.ngrok.com/get-started/your-authtoken"
    fi
done

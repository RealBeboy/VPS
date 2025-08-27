#!/bin/bash

read -p "Do you want to edit docker-compose.yml? (yes/no): " answer

if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
    cd /project/sandbox/user-workspace/windows
    nano docker-compose.yml
else
    cat ~/.config/playit_gg/playit.toml
fi

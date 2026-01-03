#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/homeassistant

./stopHomeassistant.sh
docker image rm ghcr.io/home-assistant/home-assistant:stable
docker image rm ghcr.io/home-assistant-libs/python-matter-server:stable
docker image rm openthread/otbr:latest
docker image rm ghcr.io/homeassistant-ai/ha-mcp:latest
./startHomeassistant.sh

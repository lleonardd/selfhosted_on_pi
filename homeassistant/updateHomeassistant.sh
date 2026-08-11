#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/homeassistant

./stopHomeassistant.sh
docker image rm ghcr.io/home-assistant/home-assistant:stable
docker image rm ghcr.io/home-assistant-libs/python-matter-server:stable
docker image rm ghcr.io/homeassistant-ai/ha-mcp:latest
# otbr is deliberately not removed here: an unattended pull on 2026-08-09 shipped
# a broken build and took every Matter-over-Thread device offline.
./startHomeassistant.sh

# Wait for OTBR to initialize, then restart only HA to establish connection
echo "Waiting 30 seconds for OTBR to initialize..."
sleep 60
echo "Restarting Home Assistant container to establish OTBR connection..."
docker restart homeassistant

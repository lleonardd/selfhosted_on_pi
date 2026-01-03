#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/CloudflareTunnel

./stopTunnel.sh
docker image rm cloudflared-tunnel
./startTunnel.sh

#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/pihole

./stopPihole.sh
docker image rm pihole/pihole:latest
./startPihole.sh

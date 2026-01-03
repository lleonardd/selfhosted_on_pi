#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/pihole

docker-compose -f composePihole.yml down
docker-compose -f composePihole.yml up -d

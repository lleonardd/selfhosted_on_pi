#!/bin/bash
export PATH=$PATH:/usr/local/bin
cd /home/pi/services/Nextcloud

./stopCloud.sh
docker image rm nextcloud
./startCloud.sh

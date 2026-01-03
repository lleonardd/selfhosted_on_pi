#!/bin/bash
export PATH=$PATH:/usr/local/bin

# Update all services sequentially
echo "Starting updates at $(date)"

echo "Updating Nextcloud..."
/bin/sh /home/pi/services/Nextcloud/updateCloud.sh

echo "Updating Home Assistant..."
/bin/sh /home/pi/services/homeassistant/updateHomeassistant.sh

echo "Updating Pi-hole..."
/bin/sh /home/pi/services/pihole/updatePihole.sh

echo "Updating Cloudflare Tunnel..."
/bin/sh /home/pi/services/CloudflareTunnel/updateTunnel.sh

echo "All updates completed at $(date)"

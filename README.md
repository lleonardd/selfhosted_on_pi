# Services (Raspberry Pi)

This repository contains scripts and Docker compose files to manage local services on a Raspberry Pi.

Structure overview:

- `CloudflareTunnel/` — compose and scripts for Cloudflare Tunnel
- `homeassistant/` — Home Assistant compose and management scripts
- `HsPong/` — Haskell Pong game (backend + frontend) and Dockerfile
- `Nextcloud/` — Nextcloud compose and management scripts
- `pihole/` — Pi-hole compose and management scripts
- `StatusMails/`, `temperatureEmail/` — scripts for status and temperature email reporting

Top-level scripts:

- `startAll.sh`, `stopAll.sh`, `restartAll.sh`, `updateAll.sh` — convenience scripts to manage all services
- `updateSystem.sh` — weekly `apt update` + `apt full-upgrade`, run from cron right after `updateAll.sh`; its summary goes into the Sunday status mail

How to use:

1. Clone or copy this folder to your Raspberry Pi.
2. From the repo root, run the provided start/stop scripts or cd into a service folder and use its scripts.

License: Add a license if you plan to publish this repository publicly.

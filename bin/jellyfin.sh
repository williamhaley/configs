#!/usr/bin/env bash

set -e

sudo firewall-cmd --add-port=8096/tcp

# Always try to grab the latest.
docker pull jellyfin/jellyfin:latest

docker run \
  -d \
  --restart unless-stopped \
  --name jellyfin \
  -p 8096:8096 \
  -v /mnt/zstorage/jellyfin/config:/config \
  -v /mnt/zstorage/jellyfin/cache:/cache \
  -v /home/will/Audio/Music:/media/music \
  jellyfin/jellyfin:latest


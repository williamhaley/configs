#!/usr/bin/env bash

set -e

best_audio_quality=0

yt-dlp "${1}" \
    --write-subs \
    --sub-langs "en" \
    --audio-quality "${best_audio_quality}" \
    -S ext:mp4,res:1080,fps \
    -o "%(id)s.%(ext)s" \
    --trim-filenames 8


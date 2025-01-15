#!/usr/bin/env bash

set -e

ffmpeg -i "${1}" -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" video.mp4


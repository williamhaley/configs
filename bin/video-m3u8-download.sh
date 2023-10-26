#!/usr/bin/env bash

set -e

hlsdl -o "${2}.ts" "${1}"
ffmpeg -i "${2}.ts" -map 0 -c copy "${2}.mkv"
rm "${2}.ts"

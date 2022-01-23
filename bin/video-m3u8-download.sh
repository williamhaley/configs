#!/usr/bin/env bash

set -e

hlsdl -o "${2}.ts" "${1}"
video.py -i "${2}.ts" --remux --remove-metadata --output "${2}.mkv"
rm "${2}.ts"

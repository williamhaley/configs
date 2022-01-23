#!/usr/bin/env bash

set -e

factor=30

filename=$(basename -- "${1}")
extension="${filename##*.}"
filename="${filename%.*}"

ffmpeg -y -i "${1}" -an -filter:v "setpts=PTS/${factor}" "$(dirname ${1})/${filename}.${factor}x.${extension}"


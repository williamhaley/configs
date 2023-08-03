#!/usr/bin/env bash
#
# https://www.youtube.com/watch?v=Q1SE5i7YzCg

set -e

filename=$(basename -- "${1}")
extension="${filename##*.}"
filename="${filename%.*}"

set -x
ffmpeg -i "${1}" -vf scale=2560:1440 -b:v 30M -b:a 192k -preset slow -crf 18 "${filename}.youtube.${extension}"


#!/usr/bin/env bash

set -e

main=$1
inset=$2

# Inset video in upper left hand corner

#ffmpeg \
#    -i ${main} \
#    -vf "movie=${inset} [f];[in][f] overlay=0:0 [out]" \
#    inset-output.mp4

ffmpeg -i "${main}" -i "${inset}" \
-filter_complex "[1:v]scale=320:240[ovrl],[0:v][ovrl]setpts=PTS-10/TB,[0:v][ovrl]overlay=enable=gte(t\,5):shortest=1[out]" \
-map [out] -map 0:a \
-c:v libx264 -crf 18 -pix_fmt yuv420p \
-c:a copy \
output.mp4


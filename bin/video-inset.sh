#!/usr/bin/env bash

set -e

main="${1}"
inset="${2}"

set -x

# Inset video in upper left hand corner

#ffmpeg \
#    -i "${main}" \
#    -vf "movie='${inset}' [f];[in][f] overlay=0:0 [out]" \
#    inset-output.mp4
#exit 1

#[0:v][overlay]setpts=PTS-10/TB; \

ffmpeg \
    -i "${main}" -i "${inset}" \
    -filter_complex \
        "[1:v]scale=640:360[overlay]; \
         [0:v][overlay]overlay=enable='between(t,0,20)'[out]" \
    -map [out] -map 0:a \
    -c:v libx264 -crf 18 -pix_fmt yuv420p \
    -c:a copy \
    output.mp4


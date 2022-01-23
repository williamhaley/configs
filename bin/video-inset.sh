#!/usr/bin/env bash

set -e

main=$1
inset=$2

# Inset video in upper left hand corner

ffmpeg -i ${main} -vf "movie=${inset} [f];[in][f] overlay=0:0 [out]" inset-output.mp4


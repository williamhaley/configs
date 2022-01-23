#!/usr/bin/env bash

# dimensions are out_w:out_h:x:y
width=1920
height=1080

# Remove 200 from the height, width
width=1720
height=880
dimensions="${width}:${height}:100:100"

ffmpeg -i "${1}" -filter:v "crop=${dimensions}" cropped.mp4


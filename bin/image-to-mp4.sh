#!/usr/bin/env bash

set -e

video_duration=3

width=1920
height=1080

filename=$(basename "${1}")
filename="${filename%.*}"

ffmpeg \
	-loop 1 \
	-f image2 -i "${1}" \
	-f lavfi -i aevalsrc=0 `# Empty audio. This makes subsequent manipulations a bit simpler` \
	-c:v libx265 \
	-t "${video_duration}" \
	-pix_fmt yuv420p \
	-c:a aac \
	-b:a 192k \
	-vf "scale=${width}:${height}:force_original_aspect_ratio=1,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p" \
	"$(dirname "${1}")/${filename}.mp4"

#!/usr/bin/env bash

# Use -d as a portable flag across Unix/Linux
dir=$(mktemp -d)

width=720
fps=20

ffmpeg \
	-i "${1}" \
	-vf fps="${fps}",scale=${width}:-1:flags=lanczos,palettegen \
	"${dir}/palette.png"

source="${1}"
filename=$(basename -- "${source}")
extension="${filename##*.}"
filename="${filename%.*}"

ffmpeg \
	-i "${1}" -i "${dir}/palette.png" \
	-filter_complex "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse" \
	"${filename}.gif"


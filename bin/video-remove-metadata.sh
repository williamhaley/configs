#!/usr/bin/env bash

set -e

orig="${1}"
name=${1%.*}
extension="${1##*.}"
temp="${name}-tmp.${extension}"

ffmpeg \
	-i "${orig}" \
	-map_metadata -1 \
	-c:v copy \
	-c:a copy \
	-y \
	-fflags +bitexact \
	-flags:v +bitexact \
	-flags:a +bitexact \
	"${temp}"

mv "${temp}" "${orig}"


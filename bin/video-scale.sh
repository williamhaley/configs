#!/usr/bin/env bash

set -e

filename="$(basename -- "${1}")"
extension="${filename##*.}"
filename="${filename%.*}"

out="$(mktemp).${extension}"

ffmpeg -i "${1}" -vf scale="${2}" "${out}"

mv "${out}" "$(dirname "${1}")/${filename}.scaled.${extension}"


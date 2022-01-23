#!/usr/bin/env bash

output="$(mktemp).mp4"
ffmpeg -i "${1}" -c copy -an "${output}"
mv "${output}" "${1}"


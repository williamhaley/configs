#!/usr/bin/env bash

# HH:MM:SS.Miliseconds
# video-split.sh video.mkv 00:20:52.200

if [ ! -f "${1}" ];
then
    printf "must pass a source file path as the first argument\n"
    exit 1
fi

if [ -z "${2}" ];
then
    printf "must pass a split time code as the second argument\n"
    exit 1
fi

filename="$(basename -- "${1}")"
extension="${filename##*.}"
filename="${filename%.*}"

ffmpeg -y -i "${1}" -ss 0 -t "${2}" "${filename}.1.${extension}"
ffmpeg -y -i "${1}" -ss "${2}" "${filename}.2.${extension}"


#!/usr/bin/env bash

start=0
duration=15

if [ ! -f "${1}" ];
then
    printf "must pass a source file path as the only argument"
    exit 1
fi

filename="$(basename -- "${1}")"
extension="${filename##*.}"
filename="${filename%.*}"

for i in {1..7};
do
    ffmpeg -y -i "${1}" -ss ${start} -t ${duration} "${filename}${i}.${extension}"
    start=$((start + duration))
done


#!/usr/bin/env bash

set -e

for f in *.MP4
do
  name="$(basename "${f}" ".MP4")"

  if [ ! -f "${name}.mkv" ]
  then
    ffmpeg -threads 2 -i "${f}" "${name}.mkv"
  fi

  if [ ! -f "${name}.30x.mkv" ]
  then
    video-speed-up-no-audio.sh "${name}.mkv"
  fi
done

rm -f manifest.txt

for f in *.30x.mkv
do
    echo "file '${f}'" >> manifest.txt
done

ffmpeg -f concat -safe 0 -i manifest.txt -c copy output.mkv


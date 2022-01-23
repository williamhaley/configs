#!/usr/bin/env bash

ffmpeg -i "${1}" -vf "transpose=1" out.mp4


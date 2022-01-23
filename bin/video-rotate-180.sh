#!/usr/bin/env bash

ffmpeg -i "${1}" -vf "transpose=2,transpose=2" out.mp4


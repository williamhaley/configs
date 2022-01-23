#!/usr/bin/env bash

set -e

ffmpeg -i "${1}" -c:s srt "${1}.srt"

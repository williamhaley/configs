#!/usr/bin/env bash

set -e

filename=$(yt-dlp "$1" -o "%(title)s" --get-filename)
sanitized=$(echo ${filename} | tr -d "\"" | tr -d "'")

yt-dlp \
	-f bestvideo+bestaudio \
	--output "${sanitized}.%(ext)s" "${1}"


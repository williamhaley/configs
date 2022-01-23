#!/usr/bin/env bash

set -e

filename=$(youtube-dl "$1" -o "%(title)s" --get-filename)
sanitized=$(echo ${filename} | tr -d "\"" | tr -d "'")

youtube-dl \
	-f bestaudio \
	--output "${sanitized}.%(ext)s" "${1}"

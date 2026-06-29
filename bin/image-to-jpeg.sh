#!/usr/bin/env bash

set -e

magick mogrify -monitor -format jpg "${1}"

mv "${1}" "${1}.original"


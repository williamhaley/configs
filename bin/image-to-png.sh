#!/usr/bin/env bash

set -e

magick mogrify -monitor -format png "${1}"

rm "${1}"


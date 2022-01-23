#!/usr/bin/env bash

set -e

magick mogrify -monitor -format jpg "${1}"

rm "${1}"


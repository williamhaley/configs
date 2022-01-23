#!/usr/bin/env bash

set -e

magick mogrify -monitor -format pdf "${1}"

rm "${1}"


#!/usr/bin/env bash

mkdir -p "${HOME}/Downloads/photos-import"
rsync -avr --remove-source-files will@192.168.0.192:/storage/uploads/ "${HOME}/Downloads/photos-import"

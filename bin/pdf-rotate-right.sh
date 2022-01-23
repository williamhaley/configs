#!/usr/bin/env bash
#
# pdf-rotate-right.sh rotates a PDF to the right by 90 degrees

qpdf --rotate=+90 --replace-input "${1}"

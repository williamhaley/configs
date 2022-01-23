#!/usr/bin/env bash
#
# pdf-split.sh separates a single PDF file into multiple pages

pdfseparate "${1}" %d.pdf

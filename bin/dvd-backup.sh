#!/usr/bin/env bash
#
# Back up old DVDs from the 2000s that I created with various mechanisms.

set -e

title="${1}"
temp_directory="$(mktemp -d)"

dvdbackup -i /dev/sr0 -o "${temp_directory}" --mirror --name="${title}"
mkisofs -V "${title}" -dvd-video -udf -o "${title}.iso" "${temp_directory}/${title}"
rm -rf "${temp_directory}"

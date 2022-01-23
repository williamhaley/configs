#!/usr/bin/env bash
#
# sync-progress.sh watches the status of the 'sync' command
# This can be used to understand how much time is left before
# 'sync' completes.
# https://unix.stackexchange.com/a/713647/87765

set -e

watch -n1 'grep -E "(Dirty|Write)" /proc/meminfo; echo; ls /sys/block/ | while read device; do awk "{ print \"$device: \"  \$9 }" "/sys/block/$device/stat"; done'


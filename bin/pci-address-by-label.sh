#!/usr/bin/env bash

set -e

# Use xargs to trim the trailing whitespace from the matching pattern.
printf "%s" "0000:$(lspci | grep -F "${1}" | grep --only-matching --extended-regex '^[a-zA-Z0-9:\.]+\s' | xargs)"

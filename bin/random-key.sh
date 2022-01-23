#!/usr/bin/env bash

# 32 characters = 256 bytes. The first parameter to this script can be used instead of the default though.
size="${1:-32}"

# Generate more data than we need since we'll trim the character set with tr
dd if=/dev/urandom bs=512 count=24 2> /dev/null | tr -dc A-Z-a-z-0-9 | head -c ${size}

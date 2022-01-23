#!/usr/bin/env bash

set -e

data_dir="$(mktemp -d)"

chromium-browser --user-data-dir="${data_dir}" --new-window --incognito --proxy-server="socks5://127.0.0.1:9050" --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" https://check.torproject.org


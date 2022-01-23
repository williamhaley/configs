#!/usr/bin/env bash

set -e

data_dir="$(mktemp -d)"

chromium-browser --user-data-dir="${data_dir}" --new-window --incognito about:blank


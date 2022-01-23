#!/usr/bin/env bash

set -e

while IFS= read -r -d '' file
do
  checksum="${file}.md5sum"

  if [ -f "${checksum}" ]
  then
    md5sum -c "${checksum}"
  fi
done < <(find . -type f -not -name "*.md5sum" -print0)


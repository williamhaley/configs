#!/usr/bin/env bash

set -e

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

interrupt()
{
  echo "Script interrupted."
  exit 1
}

trap interrupt INT

# If this prints nothing, something is wrong.
# Members of a group are the smallest unit of isolation and must be passed to a VM together.
shopt -s nullglob
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V);
do
  echo "IOMMU Group ${g##*/}:"
  for d in $g/devices/*;
  do
    echo -e "\t$(lspci -nns ${d##*/})"
  done
done


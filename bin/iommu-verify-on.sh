#!/usr/bin/env bash

set -e

[ $EUID -eq 0 ] && echo "do not run as root" >&2 && exit 1

if ! id -nG "${USER}" | grep -qw vfio;
then
  echo "user not in group vfio"
  exit 1
fi

if ! grep -qw pcie_acs_override=downstream,multifunction /proc/cmdline;
then
  echo "kernel parameter not enabled"
  exit 1
fi

# TODO I see groups listed, but not this check working :-/
# if ! sudo dmesg | grep -i -e DMAR -e IOMMU > /dev/null;
# then
#   echo "IOMMU not enabled in BIOS or otherwise not enabled"
#   exit 1
# fi

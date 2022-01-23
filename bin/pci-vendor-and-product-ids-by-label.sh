#!/usr/bin/env bash

set -e

[ $EUID -eq 0 ] && echo "do not run as root" >&2 && exit 1

address="$(pci-address-by-label.sh "${1}")"

vendorid="$(cut -c3- "/sys/bus/pci/devices/${address}/vendor")"
productid="$(cut -c3- "/sys/bus/pci/devices/${address}/device")"

printf "%s" "${vendorid}:${productid}"

#!/usr/bin/env bash

set -e

[ $EUID -eq 0 ] && echo "do not run as root" >&2 && exit 1

regex="^Bus ([0-9]+) Device ([0-9]+): ID ([0-9a-zA-Z]{4}):([0-9a-zA-Z]{4})"

if ! lsusb | grep -q -F "${1}"
then
	echo "USB device '${1}' not found"
	exit 1
fi

device="$(lsusb | grep -F "${1}")"

if ! [[ ${device} =~ ${regex} ]]
then
	echo "could not parse information for USB device '${1}'"
	exit 1
fi

bus="${BASH_REMATCH[1]}"
dev="${BASH_REMATCH[2]}"
vendorId="${BASH_REMATCH[3]}"
productId="${BASH_REMATCH[4]}"

device_owner="$(stat -c '%U' "/dev/bus/usb/${bus}/${dev}")"
device_group="$(stat -c '%G' "/dev/bus/usb/${bus}/${dev}")"

if [ "${device_owner}" != "vfio" ] && [ "${device_group}" != "vfio" ]
then
	echo "device '${1}' does not have a vfio udev rule and will not work"
	echo ""
	echo "append this to /etc/udev/rules.d/vfio.rules"
	echo ""
	echo "  SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"${vendorId}\", ATTRS{idProduct}==\"${productId}\", GROUP=\"vfio\", MODE=\"0666\""
	echo ""
	echo "then reboot or run the following commands"
	echo ""
	echo "udevadm control --reload-rules"
	echo "udevadm trigger"
	echo ""
	exit 1
fi

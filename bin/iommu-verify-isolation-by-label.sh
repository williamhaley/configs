#!/usr/bin/env bash
#
# Verify that a PCI device (most likely a GPU) is ready for use in a qemu VM.
#
#   iommu-verify-isolation-by-label.sh "NVIDIA Corporation GM206 [GeForce GTX 960] (rev a1)"
#
# This validates that the vfio driver is being used for IOMMU. Note that there
# are at least two strategies for isolating PCI devices for a qemu VM.
#
#   1. A modprobe file like 'options vfio-pci ids=abcd:efgh,..'
#   2. A boot loader kernel parameter like 'vfio-pci.ids=abcd:efgh,...'
#
# Using kernel parameters is more flexible. I have seen machines fail to boot
# because of issues with the modprobe config, and that required a rescue USB and
# regenerating the initramfs without the vfio-pci ids specified. Editing
# linux kernel boot parameters on-the-fly is often much simpler. Sometimes
# kernel parameters cannot be used like if early modesetting takes place for a
# GPU device and its driver.

set -e

[ $EUID -eq 0 ] && echo "do not run as root" >&2 && exit 1

address="$(pci-address-by-label.sh "${1}")"

driver_path="$(readlink -f "/sys/bus/pci/devices/${address}/driver")"
driver="$(basename "${driver_path}")"

vendor_and_product_ids="$(pci-vendor-and-product-ids-by-label.sh "${1}")"

if [ "${driver}" != "vfio-pci" ]
then
  # Caveats:
  # cat << EOF > /etc/udev/rules.d/vfio.rules
  # # All stubbed vfio devices
  # SUBSYSTEMS=="vfio", GROUP="vfio"
  # EOF

  # cat << EOF > /etc/security/limits.d/vfio.conf
  # @vfio soft memlock unlimited
  # @vfio hard memlock unlimited
  # EOF
  # 1. If the host and guest GPU have the same vendor:product ids, that can be a pain.
  # 2. If your pci root port is part of your IOMMU group, you must not try to isolate it. The host needs it too! Use a kernel that properly isolates _everything_
  echo "device '${address}' does not have a vfio pci stub and will not work with iommu. it is currently using driver '${driver}'"
  echo
  echo "append the address to /etc/modprobe.d/vfio.conf OR append it as a kernel parameter (that may not be an option for some devices)"
  echo
  echo "  modprobe: options vfio-pci ids=abcd:efgh,${vendor_and_product_ids},..."
  echo
  echo "  OR"
  echo
  echo "  vfio-pci.ids=abcd:efgh,..."
  echo
  echo "then rebuild initramfs OR regenerate the boot loader config and reboot"
  echo
  echo "pass the device to qemu like '-device vfio-pci,host=abcd:efgh,${vendor_and_product_ids},...'"
  exit 1
fi

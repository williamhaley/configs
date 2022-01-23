#!/usr/bin/env bash

set -e

USE_SNAPSHOT=${USE_SNAPSHOT:-true}

vm_root="/home/will/VMs/linux-throwaway"
mkdir -p "${vm_root}"

iso_file="/home/will/Downloads/archlinux-2025.01.01-x86_64.iso"

cp "/usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.4m.fd" "${vm_root}/vars.fd"
cp "/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd" "${vm_root}/nvram.fd"

disk="${vm_root}/sda.qcow2"
if [ "${USE_SNAPSHOT}" = "true" ]
then
	# Re-create the snapshot on every run.
	qemu-img create -f qcow2 -b sda.qcow2 -F qcow2 snapshot.qcow2
	disk="${vm_root}/snapshot.qcow2"
else
	# Re-create the disk on every run.
	qemu-img create -f qcow2 "${disk}" 120G
fi

#   `# USB devices` \
#   -usb -device "usb-host,vendorid=0x0bda,productid=0x8813" `# Realtek Semiconductor Corp. RTL8814AU 802.11a/b/g/n/ac Wireless Adapter` \
# iommu-verify-usb-driver.sh "Realtek Semiconductor Corp. RTL8814AU 802.11a/b/g/n/ac Wireless Adapter"
	# `# Wired virtual NIC` \
	# -nic none \

qemu-system-x86_64 \
	-enable-kvm \
	-machine q35,accel=kvm \
	-cpu EPYC,kvm=on \
	-smp 8,cores=4,sockets=2 \
	-smbios type=2 \
	`# Memory` \
	-m 4G -mem-prealloc \
	`# UEFI` \
	-drive if=pflash,format=raw,readonly=on,file="${vm_root}/vars.fd" \
	-drive if=pflash,format=raw,file="${vm_root}/nvram.fd" \
	`# SATA Controller` \
	-device ich9-ahci,id=sata \
		-device ide-hd,bus=sata.0,drive=sata0 \
		-drive id=sata0,if=none,file="${disk}" \
	-device intel-iommu,caching-mode=on \
	-cdrom "${iso_file}" \
	-boot menu=on

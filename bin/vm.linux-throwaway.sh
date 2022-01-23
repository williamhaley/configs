#!/usr/bin/env bash

set -e

vm_root="/home/will/VMs/linux-throwaway"

iommu-verify-usb-driver.sh "Realtek Semiconductor Corp. RTL8814AU 802.11a/b/g/n/ac Wireless Adapter"

qemu-system-x86_64 \
	-enable-kvm \
	-machine q35,accel=kvm \
	-cpu EPYC,kvm=on \
	-smp 8,cores=4,sockets=2 \
	-smbios type=2 \
	`# Memory` \
	-m 4G -mem-prealloc \
	`# Wired virtual NIC` \
	-nic none \
	`# UEFI` \
	-drive if=pflash,format=raw,readonly=on,file=${vm_root}/OVMF_CODE.secboot.fd `# From /usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.fd` \
	-drive if=pflash,format=raw,file=${vm_root}/nvram.fd `# From /usr/share/edk2-ovmf/x64/OVMF_VARS.fd` \
	`# SATA Controller` \
	-device ich9-ahci,id=sata \
		-device ide-hd,bus=sata.0,drive=sata0 \
		-drive id=sata0,if=none,file=${vm_root}/image/linux-throwaway.qcow2,format=qcow2 \
	-device intel-iommu,caching-mode=on \
  `# USB devices` \
  -usb -device "usb-host,vendorid=0x0bda,productid=0x8813" `# Realtek Semiconductor Corp. RTL8814AU 802.11a/b/g/n/ac Wireless Adapter` \
	-cdrom "/home/will/Downloads/linux.iso" \
	-boot menu=on

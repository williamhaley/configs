#!/usr/bin/env bash

export QEMU_AUDIO_DRV=none

# For installation
#	--disk "${machine_home}/BaseSystem.img" \

machine_home="${HOME}/VMs/macOS"

vm.py \
	--efi \
	--nvram "${machine_home}/OVMF_CODE.fd" \
	--nvram-vars "${machine_home}/OVMF_VARS-1024x768.fd" \
	--mac \
	--disk "${machine_home}/opencore.img" \
	--disk "${machine_home}/BaseSystem.img" \
	--disk "${machine_home}/macOS.qcow2" \
	--disk "${HOME}/VMs/macOS.old/macOS.qcow2" \
	--pci "Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller (rev 11)" \
	--usb "Apple, Inc. iPhone 5/5C/5S/6/SE" "guest-reset=false,id=iphone" \
	--virtual-input-devices \
	--local-share "${HOME}/Downloads"


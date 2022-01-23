#!/usr/bin/env bash
#
# Windows 11 Qemu VM with direct PCI device passthrough for an NVIDIA GPU.
#
# Drivers may be found here https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md

set -e

iommu-verify-on.sh

iommu-verify-isolation-by-label.sh "NVIDIA Corporation GM206 [GeForce GTX 960] (rev a1)"
iommu-verify-isolation-by-label.sh "NVIDIA Corporation GM206 High Definition Audio Controller (rev a1)"

# Using this to connect an Xbox controller. USB does not work. Must use Bluetooth.
iommu-verify-usb-driver.sh "Broadcom Corp. BCM20702A0 Bluetooth 4.0"
# TODO Someday try and get this working wired in!
# iommu-verify-usb-driver.sh "Microsoft Corp. Xbox Wireless Controller (model 1914)"

vm_root="/home/will/VMs/windows11"

# Start up the fake software TPM device.
swtpm socket --tpm2 -d --tpmstate dir=${vm_root}/tpm --ctrl type=unixio,path=${vm_root}/tpm/swtpm.sock --log level=20

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35,accel=kvm \
  -cpu EPYC,kvm=on \
  -smp 16,cores=4,sockets=4 \
  -smbios type=2 \
  `# Memory` \
  -m 16G -mem-prealloc \
  `# TPM` \
  -chardev socket,id=chrtpm,path=${vm_root}/tpm/swtpm.sock \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  `# Wired virtual NIC` \
  -nic user,hostfwd=tcp::8000-:8000,smb=/home/will/Downloads \
  `# UEFI` \
  -drive if=pflash,format=raw,readonly=on,file=${vm_root}/OVMF_CODE.secboot.fd `# From /usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.fd` \
  -drive if=pflash,format=raw,file=${vm_root}/nvram.fd `# From /usr/share/edk2-ovmf/x64/OVMF_VARS.fd` \
  `# SATA Controller` \
  -device ich9-ahci,id=sata \
    `# Specifically set serial/model numbers. Else, Windows 11 may do odd things during installation` \
    -device ide-hd,bus=sata.0,drive=sata0,serial=212611800050,model=WDS200T2B0B-00YS70 \
    -drive id=sata0,if=none,file=${vm_root}/image/windows11.vmdk,format=vmdk \
  -device intel-iommu,caching-mode=on \
  `# VFIO devices` \
  -device vfio-pci,host="$(pci-address-by-label.sh "VGA compatible controller: NVIDIA Corporation GM206 [GeForce GTX 960] (rev a1)")" \
  -device vfio-pci,host="$(pci-address-by-label.sh "Audio device: NVIDIA Corporation GM206 High Definition Audio Controller (rev a1)")" \
  `# Disable on-board integrated graphics for the VM` \
  -nographic -vga none \
  `# USB devices` \
  -usb -device "usb-host,vendorid=0x046d,productid=0x0825" `# Logitech, Inc. Webcam C270` \
  -usb -device "usb-host,vendorid=0x046d,productid=0xc52b" `# Logitech, Inc. Unifying Receiver` \
  -usb -device "usb-host,vendorid=0x0a5c,productid=0x21e8" `# Broadcom Corp. BCM20702A0 Bluetooth 4.0` \
  `# Audio` \
  -device ich9-intel-hda,addr=1f.1 -audiodev pa,id=snd0 -device hda-output,audiodev=snd0

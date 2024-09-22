#!/usr/bin/env bash
#
# Windows 11 Qemu VM with direct PCI device passthrough for an NVIDIA GPU.
#
# Drivers may be found here https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md

set -e

usb_host_devices=('046d:c52b' '0a5c:21e8')
pci_devices=('10de:1c03')

function verify_usb_device_permissions() {
  for usb_host_device in "${usb_host_devices[@]}"
  do
    IFS=: read -r idVendor idProduct <<< "${usb_host_device}"

    for device in /sys/bus/usb/devices/*
    do
      if [ -f "${device}/idVendor" ] && [ -f "${device}/idProduct" ] && [ "$(< "${device}/idVendor")" = "${idVendor}" ] && [ "$(< "${device}/idProduct")" = "${idProduct}" ]
      then
        bus="$(printf "%03d" "$(cat "${device}/busnum")")"
        dev="$(printf "%03d" "$(cat "${device}/devnum")")"

        device_owner="$(stat -c '%U' "/dev/bus/usb/${bus}/${dev}")"
        device_group="$(stat -c '%G' "/dev/bus/usb/${bus}/${dev}")"

        if [ "${device_owner}" != "vfio" ] && [ "${device_group}" != "vfio" ]
        then
          echo "Problem with USB device: ${usb_host_device}: ${device_owner}:${device_group}"
          echo "Run the setup function and reboot"
          exit 1
        fi
      fi
    done
  done
}

function verify_pci_isolation() {
  for pci_device in "${pci_devices[@]}"
  do
    for device in /sys/bus/pci/devices/*
    do
      IFS=: read -r idVendor idProduct <<< "${pci_device}"
      if [ -f "${device}/vendor" ] && [ -f "${device}/device" ] && [ "$(< "${device}/vendor")" = "0x${idVendor}" ] && [ "$(< "${device}/device")" = "0x${idProduct}" ]
      then
        driver_path="$(readlink -f "${device}/driver")"
        driver="$(basename "${driver_path}")"
        
        if [ "${driver}" != "vfio-pci" ]
        then
          echo "Problem with PCI device: ${pci_device}: ${device}"
          echo "Run the setup function and reboot"
          exit 1
        fi
      fi
    done
  done
}

function setup() {
  # Set up permissions for non-root.
  sudo groupadd vfio || true
  sudo usermod -a -G vfio "${USER}"

  sudo tee /etc/udev/rules.d/vfio.rules <<EOF
# All stubbed vfio devices belong to the vfio group.
SUBSYSTEMS=="vfio", GROUP="vfio"
EOF
  for usb_host_device in "${usb_host_devices[@]}"
  do
    IFS=: read -r idVendor idProduct <<< "${usb_host_device}"
  sudo tee -a /etc/udev/rules.d/vfio.rules << EOF
# USB Host device.
SUBSYSTEMS=="usb", ATTRS{idVendor}=="${idVendor}", ATTRS{idProduct}=="${idProduct}", GROUP="vfio", MODE="0666"
EOF
  done

  joined="$(IFS=, ; echo "${pci_devices[*]}")"
  sudo tee /etc/modprobe.d/vfio.conf > /dev/null << EOF
softdep drm pre: vfio-pci

# PCI devices.
options vfio-pci ids=${joined}
EOF

  sudo mkdir -p /etc/security/limits.d
  sudo tee /etc/security/limits.d/vfio.conf <<EOF
@vfio soft memlock unlimited
@vfio hard memlock unlimited
EOF

  sudo mkinitcpio -P

  echo "reboot to apply changes"
  echo "make sure these MODULES are set up in /etc/mkinitcpio.conf: vfio_pci vfio vfio_iommu_type1"
  echo "make sure these HOOKS are set up in /etc/mkinitcpio.conf: modconf"
}

function debug() {
  # Verifying that the configuration worked
  # Reboot and verify that vfio-pci has loaded properly and that it is now bound to the right devices. 
  sudo dmesg | grep -i vfio

  # It is not necessary for all devices (or even expected device) from vfio.conf to be in dmesg output. Even if a device does not appear, it might still be visible and usable in the guest virtual machine. 
  sudo lspci -nnk -d 10de:1c03
  sudo lspci -nnk -d 10de:10f1
}

# setup
# exit 1

verify_usb_device_permissions
verify_pci_isolation

vm_root="/home/will/VMs/windows11"

# Start up the fake software TPM device.
# swtpm socket --tpm2 -d --tpmstate dir=${vm_root}/tpm --ctrl type=unixio,path=${vm_root}/swtpm.sock --log level=20
# `# TPM` \
# -chardev socket,id=chrtpm,path=${vm_root}/swtpm.sock \
# -tpmdev emulator,id=tpm0,chardev=chrtpm \
# -device tpm-tis,tpmdev=tpm0 \

usb_args=()
for usb_host_device in "${usb_host_devices[@]}"
do
  IFS=: read -r idVendor idProduct <<< "${usb_host_device}"
  usb_args+=("-usb -device usb-host,vendorid=0x${idVendor},productid=0x${idProduct}")
done

pci_args=()
for pci_device in "${pci_devices[@]}"
do
  for device in /sys/bus/pci/devices/*
  do
    IFS=: read -r idVendor idProduct <<< "${pci_device}"
    if [ -f "${device}/vendor" ] && [ -f "${device}/device" ] && [ "$(< "${device}/vendor")" = "0x${idVendor}" ] && [ "$(< "${device}/device")" = "0x${idProduct}" ]
    then
      pci_args+=("-device vfio-pci,host=$(basename "${device}")")
    fi
  done
done

set -x

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35,accel=kvm \
  -cpu EPYC,kvm=on \
  -smp 16,cores=4,sockets=4 \
  -smbios type=2 \
  `# Memory` \
  -m 16G -mem-prealloc \
  `# Wired virtual NIC` \
  -nic user,hostfwd=tcp::8000-:8000,smb=/home/will/Downloads \
  `# UEFI` \
  -drive if=pflash,format=raw,readonly=on,file=${vm_root}/OVMF_CODE.secboot.fd `# From /usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.fd` \
  -drive if=pflash,format=raw,file=${vm_root}/nvram.fd `# From /usr/share/edk2-ovmf/x64/OVMF_VARS.fd` \
  `# SATA Controller` \
  -device ich9-ahci,id=sata \
    `# Specifically set serial/model numbers. Else, Windows 11 may do odd things during installation` \
    -device ide-hd,bus=sata.0,drive=sata0,serial=212611800050,model=WDS200T2B0B-00YS70 \
    -drive id=sata0,if=none,file=${vm_root}/windows11.qcow2,format=qcow2 \
  -device intel-iommu,caching-mode=on \
  `# VFIO devices ` \
  ${pci_args[@]} \
  `# Disable on-board integrated graphics for the VM` \
  -nographic -vga none \
  `# USB devices` \
  ${usb_args[@]} \
  `# Audio` \
  -device ich9-intel-hda,addr=1f.1 -audiodev pipewire,id=snd0 -device hda-output,audiodev=snd0

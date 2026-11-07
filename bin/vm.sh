#!/usr/bin/env bash
#
# Windows 11 Qemu VM with direct PCI device passthrough for a physical GPU.
#
# Drivers may be found here https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md

set -e

[ $EUID -eq 0 ] && echo "do not run as root" >&2 && exit 1

# sudo udevadm control --reload-rules && sudo udevadm trigger

vm_name="${1}"

if [ -z "${vm_name}" ]
then
  echo "Pass a single arg. The name of the VM"
  exit 1
fi

vm_root="${HOME}/VMs/${vm_name}"

if [ ! -d "${vm_root}" ]
then
  echo "'${vm_root}' does not exist"
  exit 1
fi

get_val()
{
  override_config=""
  if [ -f "${vm_root}/config.yaml" ]
  then
    override_config="${vm_root}/config.yaml"
  fi

  yq eval-all '. as $item ireduce ({}; . *+ $item )' "${HOME}/VMs/global.config.yaml" ${override_config} | yq eval "${1} | envsubst"
}

vars_source="$(get_val ".uefi.vars")"
nvram_source="$(get_val ".uefi.nvram")"
memory="$(get_val ".memory")"
readarray -t pci_devices < <(get_val ".vfio.pci[].address")
readarray -t usb_host_devices < <(get_val ".vfio.usb[].address")
readarray -t cdrom_devices < <(get_val ".cdrom[]")
readarray -t additional_args < <(get_val ".args[]")

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
    verified=false
    for device in /sys/bus/pci/devices/*
    do
      IFS=: read -r idVendor idProduct <<< "${pci_device}"
      if [ -f "${device}/vendor" ] && [ -f "${device}/device" ] && [ "$(< "${device}/vendor")" = "0x${idVendor}" ] && [ "$(< "${device}/device")" = "0x${idProduct}" ]
      then
        verified=true
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

    if [ "${verified}" = "false" ]
    then
      echo "Problem with PCI device: ${pci_device}. Could not find it in /sys/bus/pci/devices"
      exit 1
    fi
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

# Start up the fake software TPM device.
# swtpm socket --tpm2 -d --tpmstate dir=${vm_root}/tpm --ctrl type=unixio,path=${vm_root}/swtpm.sock --log level=20
# `# TPM` \
# -chardev socket,id=chrtpm,path=${vm_root}/swtpm.sock \
# -tpmdev emulator,id=tpm0,chardev=chrtpm \
# -device tpm-tis,tpmdev=tpm0 \

cdroms=()
for cdrom in "${cdrom_devices[@]}"
do
  cdroms+=("-drive "file=${cdrom},media=cdrom,index=${#cdroms[@]}"")
done

usb_args=()
for usb_host_device in "${usb_host_devices[@]}"
do
  IFS=: read -r idVendor idProduct <<< "${usb_host_device}"
  usb_args+=("-usb -device usb-host,vendorid=0x${idVendor},productid=0x${idProduct}")
done

addr_index=0
#pci_args=("-device pcie-root-port,id=root_port1,chassis=0,slot=0,bus=pcie.0")
#pci_args=("-device pcie-root-port,id=root_port1,chassis=1,slot=1,bus=pcie.0,addr=01.0")
#pci_args=()
#pci_args=("-device pci-bridge,id=will_gpu_bridge,chassis_nr=1,bus=pcie.0,addr=1a.0")
pci_args=("-device pcie-root-port,id=will_gpu_bridge,chassis=1,slot=1,bus=pcie.0,addr=1a.0")
for pci_device in "${pci_devices[@]}"
do
  for device in /sys/bus/pci/devices/*
  do
    IFS=: read -r idVendor idProduct <<< "${pci_device}"
    if [ -f "${device}/vendor" ] && [ -f "${device}/device" ] && [ "$(< "${device}/vendor")" = "0x${idVendor}" ] && [ "$(< "${device}/device")" = "0x${idProduct}" ]
    then
      # pci_args+=("-device vfio-pci,host=$(basename "${device}"),id=hostdev${addr_index},bus=root_port1,addr=00.${addr_index}")
      # pci_args+=("-device vfio-pci,host="$(basename "${device}")",bus=root_port1,addr=00.${addr_index}")
      # pci_args+=("-device vfio-pci,host=$(basename "${device}"),bus=will_gpu_bridge,addr=00.${addr_index}")
      pci_args+=("-device vfio-pci,host=$(basename "${device}"),bus=will_gpu_bridge,addr=00.${addr_index}")
      if [ "${addr_index}" -eq 0 ]
      then
        pci_args[-1]+=",multifunction=on"
      fi

      addr_index=$((addr_index+1))

      romfile="$(yq '.vfio.pci[] | select(.address == "'"${pci_device}"'") | .romfile // ""' "${vm_root}/config.yaml")"
      if [ -n "${romfile}" ]
      then
        pci_args[-1]+=",multifunction=on,romfile=${romfile}"
      fi
    fi
  done
done

vars_fd="${vm_root}/vars.fd"
if [ ! -f "${vars_fd}" ]
then
  cp "${vars_source}" "${vars_fd}"
fi

nvram_fd="${vm_root}/nvram.fd"
if [ ! -f "${nvram_fd}" ]
then
  cp "${nvram_source}" "${nvram_fd}"
fi

primary_disk="${vm_root}/sda1.qcow2"
if [ ! -f "${primary_disk}" ]
then
  # No disk exists. Make a new one every time.
  primary_disk="${vm_root}/temp.qcow2"
  qemu-img create -f qcow2 "${primary_disk}" 200G
fi

set -x

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35,accel=kvm \
  `# Passing the host CPU and specifying the Hyper-v enlightenments saw a big performance boost on Ryzen https://wiki.archlinux.org/title/QEMU#Improve_virtual_machine_performance` \
  -cpu host,kvm=on,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,hv_frequencies,hv_reset,hv_vpindex,hv_stimer,hv_synic,hv-vendor-id=AUTHENTICAMD \
  -smp 6,sockets=1,cores=6,threads=1 \
  -smbios type=2 \
  ${cdroms[@]} \
  `# Memory` \
  -m "${memory}" -mem-prealloc \
  `# Wired virtual NIC` \
  `#-nic user,hostfwd=tcp::8000-:8000,smb=/home/will/Downloads` \
  -netdev user,id=net0,smb=/home/will/Downloads -device virtio-net-pci,netdev=net0 \
  `# UEFI` \
  -drive if=pflash,format=raw,readonly=on,file=${vars_fd} \
  -drive if=pflash,format=raw,file=${nvram_fd} \
  `# SATA Controller` \
  -device ich9-ahci,id=sata \
    `# Specifically set serial/model numbers. Else, Windows 11 may do odd things during installation` \
    -device ide-hd,bus=sata.0,drive=sata0,serial=212611800050,model=WDS200T2B0B-00YS70 \
    -drive id=sata0,if=none,file=${primary_disk},format=qcow2 \
  `# VFIO devices ` \
  ${pci_args[@]} \
  `# USB devices` \
  ${usb_args[@]} \
  `# Audio` \
  -device ich9-intel-hda,addr=1f.1 -audiodev pipewire,id=snd0 -device hda-output,audiodev=snd0 \
  ${additional_args[@]}


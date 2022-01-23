#!/usr/bin/env bash
#
# Xubuntu Qemu VM with Pulse/Pipewire audio, KVM, runs as a daemon, SSH
# port-forwarding for host to guest SSH access, USB forwarding, and a split VMDK
# hard disk.

qemu-system-x86_64 \
  -mem-prealloc -enable-kvm -daemonize \
  -smbios type=2 \
  -machine q35,accel=kvm \
  -cpu host,kvm=on -smp 8 `# Dedicate 8 physical CPU cores` \
  -m 16G \
  -drive "file=${HOME}/VMs/work/images/work.new/work.vmdk" `# Primary OS disk` \
  -drive "file=${HOME}/VMs/work/images/storage/storage.vmdk" `# Data disk` \
  -device ich9-intel-hda,addr=1f.1 \
  -audiodev pa,id=snd0 -device hda-output,audiodev=snd0 `# Audio device using Intel HD Audio with pa (PulseAudio/PipeWire) on the host` \
  -usb -device usb-host,vendorid=0x046d,productid=0x0825 `# Logitech, Inc. Webcam C270` \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0,id=net0 `# NIC with port-forwarding 2222 (host) -> 22 (guest)`

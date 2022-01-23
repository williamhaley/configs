#!/usr/bin/env bash

set -e

pushd "${HOME}/VMs/debian-arm"

qemu-system-arm \
  -m 16G \
  -machine type=virt,gic-version=3 \
  -cpu max \
  -smp 16 \
  -initrd "./initrd.img-from-guest" \
  -kernel "./vmlinuz-from-guest" \
  -append "console=ttyAMA0 root=/dev/sda2" \
  -drive file="./debian-arm.sda.qcow2",id=hd,if=none,media=disk \
    -device virtio-scsi-device \
    -device scsi-hd,drive=hd \
  -netdev user,id=net0,hostfwd=tcp::5555-:22 \
    -device virtio-net-device,netdev=net0 \
  -nographic

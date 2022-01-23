#!/usr/bin/env bash
#
# Windows 98 Qemu VM.

set -e

# -cdrom ~/Software/Windows\ and\ DOS/Windows\ 98\ First\ Edition.iso \

pushd "${HOME}/VMs/windows98"

qemu-system-i386 \
  -nodefaults \
  -rtc base=localtime \
  -m 1G \
  -hda "./image/windows98.vmdk" \
  -cdrom "${HOME}/Software/Windows and DOS/Windows 98 First Edition.iso" \
  -device lsi \
  -device sb16 \
  -audiodev pa,id=snd0,out.buffer-length=10000,out.period-length=2500 \
  -device VGA

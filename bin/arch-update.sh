#!/usr/bin/env bash
#
# Script to update my archlinux installation. This updates the archlinux keyring first.

set -e

sudo pacman -Sy archlinux-keyring --needed
sudo pacman -Syyu

#!/usr/bin/env bash

set -e

. /etc/makepkg.conf

PKGCACHE=$((grep -m 1 '^CacheDir' /etc/pacman.conf || echo 'CacheDir = /var/cache/pacman/pkg') | sed 's/CacheDir = //')

pkgdirs=("$@" "$PKGDEST" "$PKGCACHE")

rm -f /tmp/files.list
rm -f /tmp/pkglist.orig

paclog --pkglist --logfile=/var/log/pacman.log | while read -r -a parampart
do
  pkgname="${parampart[0]}-${parampart[1]}-*.pkg.tar.{xz,zst}"
  for pkgdir in ${pkgdirs[@]}; do
    pkgpath="$pkgdir"/$pkgname
    [ -f $pkgpath ] && { echo $pkgpath >> /tmp/files.list; break; };
  done || echo ${parampart[0]} 1>&2 >> /tmp/pkglist.orig
done

{ cat /tmp/pkglist.orig; pacman -Slq; } | sort | uniq -d > /tmp/pkglist

yay -S $(< /tmp/pkglist.orig) --noscriptlet --dbonly --overwrite "*" --nodeps --needed


#!/usr/bin/env bash
#
# Arch Linux installation script with encryption (with password) and swap file
#
# Defaults to a UEFI install, but can do MBR with LEGACY_BOOT=true
#
# Please do not go overboard with this script. Keep it dead simple.

set -e

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

if [ ! -b "${1}" ]
then
	echo "specify a block device first"
	exit 1
fi

##############################################################################
# Variables, defaults, prepare the host system                               #
##############################################################################
CUSTOM_MIRROR=${CUSTOM_MIRROR:-"192.168.0.120:9129"}
LEGACY_BOOT=${LEGACY_BOOT:-false}
SWAP_SIZE=${SWAP_SIZE:-12G} # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#What_about_swap_space.3F

disk="${1}"

# https://unix.stackexchange.com/a/500910/87765
partition_separator=""
if [[ ${disk:(-1)} =~ ^[0-9]$ ]]
then
	partition_separator="p"
fi

boot_partition="${disk}${partition_separator}1"
swap_partition="${disk}${partition_separator}2"
root_partition="${disk}${partition_separator}3"
root_password=${ROOT_PASSWORD:-password}
encryption_password=""
while true
do
  read -r -s -p "encryption password: " encryption_password
  echo
  read -r -s -p "confirm: " encryption_password_confirm
  echo
  if [ "${encryption_password}" = "${encryption_password_confirm}" ]
  then
	break
  fi
  echo "passwords do not match"
  exit 1
done

# If it's an older machine the clock may be wrong ruining the install process.
date --set "$(curl --silent --head http://google.com | grep -e '^Date:' | sed 's/Date: //g')"
hwclock -w --utc

if [ "${LEGACY_BOOT}" != true ] && ! test -d /sys/firmware/efi
then
	echo "LEGACY_BOOT not enabled, but no /sys/firmeware/efi found"
	exit 1
fi

##############################################################################
# Disks                                                                      #
##############################################################################
wipefs -a "${disk}"

if [ "${LEGACY_BOOT}" = "true" ]
then
	# For legacy systems with no UEFI use an MBR disk.
	printf "o\nn\np\n1\n\n+1G\nt\n1\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
	partprobe || true
	printf "n\np\n2\n\n+%s\nt\n2\n82\nw\n" "${SWAP_SIZE}" | fdisk --wipe always --wipe-partitions always "${disk}"
	partprobe || true
	printf "n\np\n\n\n\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
else
	printf "o\nY\nw\nY\n" | gdisk "${disk}"
	printf "n\n1\n\n+1G\nEF00\nw\nY\n" | gdisk "${disk}"
	printf "n\n2\n\n+%s\n8200\nw\nY\n" "${SWAP_SIZE}" | gdisk "${disk}"
	printf "n\n3\n\n\n\n8300\nw\nY\n" | gdisk "${disk}"
fi

mkfs.fat -F 32 "${boot_partition}"

# https://wiki.archlinux.org/title/swap#Swap_file
mkswap "${swap_partition}"

if [ -n "${encryption_password}" ]
then
	echo "${encryption_password}" | cryptsetup -q luksFormat "${root_partition}"
	echo "${encryption_password}" | cryptsetup -q open "${root_partition}" cryptroot
	mkfs.ext4 -F /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
else
	mkfs.ext4 -F "${root_partition}"
	mount "${root_partition}" /mnt
fi

boot_part_uuid=$(blkid -s UUID -o value "${boot_partition}")
mount --mkdir "/dev/disk/by-uuid/${boot_part_uuid}" /mnt/boot

##############################################################################
# Troubleshooting steps. Seem occasionally necessary for reasons unclear     #
##############################################################################
# https://www.reddit.com/r/archlinux/comments/15730ne/pacmankey_init_causing_problems_and_pacman_sy/
# https://bbs.archlinux.org/viewtopic.php?id=283207
# https://wiki.archlinux.org/title/Pacman/Package_signing#Resetting_all_the_keys
# https://bbs.archlinux.org/viewtopic.php?id=201895
rm -f /etc/pacman.d/gnupg/* || true
gpg --refresh-keys
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring

##############################################################################
# Install                                                                    #
##############################################################################
config_file="/etc/pacman.conf"

if [ -n "${CUSTOM_MIRROR}" ]
then
	# shellcheck disable=SC2016
	echo 'Server = http://'"${CUSTOM_MIRROR}"'/repo/archlinux/$repo/os/$arch' > "/etc/pacman.d/custom.mirrorlist"

	config_file="/etc/pacman.custom.conf"
	sed "s|/etc/pacman.d/mirrorlist|/etc/pacman.d/custom.mirrorlist|g" /etc/pacman.conf > "${config_file}"
fi

pacstrap -C "${config_file}" -K /mnt base linux linux-firmware grub efibootmgr intel-ucode amd-ucode dhcpcd iwd nano git curl wget rsync openssh ntp sudo base-devel

# Seems like reflector overrides the chroot mirrorlist during pacstrap? Force the custom mirror.
if [ -n "${CUSTOM_MIRROR}" ]
then
	cp /etc/pacman.d/custom.mirrorlist /mnt/etc/pacman.d/mirrorlist
fi

# Base modules for the kernel
sed -i -e "s|^HOOKS=.*|HOOKS=\(base udev autodetect modconf block encrypt filesystems keyboard fsck\)|" /mnt/etc/mkinitcpio.conf
# 'bochs' module provides the cirrus/bochs kernel module for Qemu GPU/video support. Loading this module prevents the mkinitcpio luks disk encryption password prompt text from being garbled.
sed -i -e "s|^MODULES=.*|MODULES=\(nls_cp437 vfat ext4 bochs\)|" /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio --allpresets

##############################################################################
# Mounts                                                                     #
##############################################################################
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "${swap_partition} none swap sw 0 0" >> /mnt/etc/fstab

##############################################################################
# Boot loader                                                                #
##############################################################################
if [ -n "${encryption_password}" ]
then
	root_part_uuid=$(blkid -s UUID -o value "${root_partition}")
	# Add this to the GRUB_CMDLINE_LINUX if we boot from a key file on another partition.
	# key_command="cryptkey=UUID=${key_part_uuid}:vfat:/root.key"
	sed -i -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${root_part_uuid}:cryptroot\"|g" /mnt/etc/default/grub
	sed -i -e "s|#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|g" /mnt/etc/default/grub
fi

if [ "${LEGACY_BOOT}" = "true" ]
then
	arch-chroot /mnt grub-install --target=i386-pc "${disk}"
else
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
fi

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

##############################################################################
# AUR helper                                                                 #
##############################################################################
mkdir -p /etc/sudoers.d
printf "aur-user ALL = (ALL) NOPASSWD: /usr/bin/pacman\n" > /mnt/etc/sudoers.d/01_aur
arch-chroot /mnt useradd --create-home aur-user
arch-chroot /mnt pacman -Sy --needed --noconfirm git base-devel go `# Need go for yay`
arch-chroot /mnt su -c "git clone https://aur.archlinux.org/yay.git /tmp/yay && pushd /tmp/yay && makepkg --install --noconfirm --syncdeps" aur-user

##############################################################################
# Configure the installation                                                 #
##############################################################################
arch-chroot /mnt chpasswd <<< "root:${root_password}"

##############################################################################
# Clean up                                                                   #
##############################################################################
umount /mnt/boot || true
umount /mnt || true
cryptsetup close cryptroot || true

echo "ok"

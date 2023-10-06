#!/usr/bin/env bash
#
# Arch Linux installation script with encryption (with password) and swap file
#
# Defaults to a UEFI install, but can do MBR with LEGACY_BOOT=true
#
# Please do not go overboard with this script. Keep it dead simple.
# This should be idempotent (re-runnable) with no negative effects.

set -e

LEGACY_BOOT=${LEGACY_BOOT:-false}

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

if [ ! -b "${1}" ]
then
	echo "specify a block device first"
	exit 1
fi

disk="${1}"

# https://unix.stackexchange.com/a/500910/87765
partition_separator=""
if [[ ${disk:(-1)} =~ ^[0-9]$ ]]
then
	partition_separator="p"
fi

boot_partition="${disk}${partition_separator}1"
root_partition="${disk}${partition_separator}2"
encryption_password=${ENCRYPTION_PASSWORD:-""}
root_password=${ROOT_PASSWORD:-password}

# If it's an older machine the clock may be wrong ruining the install process.
date --set "$(curl -s --head http://google.com | grep -e '^Date:' | sed 's/Date: //g')"
hwclock -w --utc

function clean_up()
{
	umount /mnt/boot || true
	umount /mnt/efi || true
	umount /mnt || true
	cryptsetup close cryptroot || true
}

trap clean_up EXIT

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
	printf "o\nn\np\n1\n\n+500M\nt\n1\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
	partprobe || true
	printf "n\np\n\n\n\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
else
	printf "o\nY\nw\nY\n" | gdisk "${disk}"
	printf "n\n1\n\n+550M\nEF00\nw\nY\n" | gdisk "${disk}"
	printf "n\n2\n\n\n\n8300\nw\nY\n" | gdisk "${disk}"
fi

mkfs.fat -F 32 "${boot_partition}"

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
pacstrap -K /mnt base linux linux-firmware grub efibootmgr intel-ucode amd-ucode dhcpcd iwd nano git curl wget rsync openssh ntp sudo base-devel

# Base modules for the kernel
sed -i -e "s|^HOOKS=.*|HOOKS=\(base udev autodetect modconf block encrypt filesystems keyboard fsck\)|" /mnt/etc/mkinitcpio.conf
sed -i -e "s|^MODULES=.*|MODULES=\(nls_cp437 vfat ext4\)|" /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio --allpresets

##############################################################################
# Swap file                                                                  #
##############################################################################
# https://wiki.archlinux.org/title/swap#Swap_file
dd if=/dev/zero of=/mnt/swapfile bs=1M count=1k status=progress
chmod 0600 /mnt/swapfile
mkswap -U clear /mnt/swapfile

##############################################################################
# Mounts                                                                     #
##############################################################################
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

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
# Configure the installation                                                 #
##############################################################################
arch-chroot /mnt chpasswd <<< "root:${root_password}"

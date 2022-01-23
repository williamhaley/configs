#!/usr/bin/env bash

# Please do not go overboard with this script. Keep it dead simple.
# This should be idempotent (re-runnable) with no negative effects.

set -ex -ou pipefile

LEGACY_BOOT=${LEGACY_BOOT:-false}

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

if [ ! -b "${1}" ]
then
	echo "specify a block device first"
	exit 1
fi
disk="${1}"
encryption_password="${2}"

# If it's an older machine the clock may be wrong ruining the install process.
date --set "$(curl -s --head http://google.com | grep -e '^Date:' | sed 's/Date: //g')"
hwclock -w --utc

function clean_up()
{
	umount /mnt/boot || true
	umount /mnt || true
	cryptsetup close cryptroot || true
}
trap clean_up EXIT

wipefs -a "${disk}"

if [ "${LEGACY_BOOT}" != true ] && ! test -d /sys/firmware/efi
then
	echo "LEGACY_BOOT not enabled, but no /sys/firmeware/efi found"
	exit 1
fi

if [ "${LEGACY_BOOT}" = "true" ]
then
	# For legacy systems with no UEFI use an MBR disk.
	printf "o\nn\np\n1\n\n+500M\nt\n1\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
	partprobe || true
	printf "n\np\n\n\n+4G\nt\n\n82\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
	partprobe || true
	printf "n\np\n\n\n\nw\n" | fdisk --wipe always --wipe-partitions always "${disk}"
else
	parted --script "${disk}" \
		mklabel gpt \
		mkpart primary 1MiB 1GiB \
		mkpart primary 1GiB 5GiB \
		mkpart primary 5GiB 100%
fi

mkfs.fat -F 32 "${disk}1"
mkswap "${disk}2"

if [ -n "${encryption_password}" ]
then
	echo "${encryption_password}" | cryptsetup -q luksFormat "${disk}3"
	echo "${encryption_password}" | cryptsetup -q open "${disk}3" cryptroot
	mkfs.ext4 -F /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
else
	mkfs.ext4 -F "${disk}3"
	mount "${disk}3" /mnt
fi

mkdir /mnt/boot
boot_part_uuid=$(blkid -s UUID -o value "${disk}1")
mount "/dev/disk/by-uuid/${boot_part_uuid}" /mnt/boot
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware grub efibootmgr intel-ucode amd-ucode dhcpcd iwd nano
sed -i -e "s|^HOOKS=.*|HOOKS=\(base udev autodetect modconf block encrypt filesystems keyboard fsck\)|" /mnt/etc/mkinitcpio.conf
sed -i -e "s|^MODULES=.*|MODULES=\(nls_cp437 vfat ext4\)|" /mnt/etc/mkinitcpio.conf
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "UUID=$(blkid -s UUID -o value "${disk}2") none swap defaults 0 0" >> /mnt/etc/fstab

arch-chroot /mnt mkinitcpio --allpresets

if [ "${LEGACY_BOOT}" = "true" ]
then
	arch-chroot /mnt grub-install --target=i386-pc "${disk}"
else
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
fi

root_part_uuid=$(blkid -s UUID -o value "${disk}3")

if [ -n "${encryption_password}" ]
then
	# Add this to the GRUB_CMDLINE_LINUX if we boot from a key file on another partition.
	# key_command="cryptkey=UUID=${key_part_uuid}:vfat:/root.key"
	sed -i -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${root_part_uuid}:cryptroot\"|g" /mnt/etc/default/grub
	sed -i -e "s|#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|g" /mnt/etc/default/grub
fi

while ! arch-chroot /mnt passwd root; do echo "error. try again"; done

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

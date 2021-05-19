#!/bin/bash

set -eo pipefail
IFS=$'\n\t'

locale_gen="en_US.UTF-8 UTF-8"
locale_conf="LANG=en_US.UTF-8"
timezone="/usr/share/zoneinfo/US/Central"
applications="bash-completion git iw wpa_supplicant openssh memtest86+ dhcpcd netctl dialog nano"
mirror='https://mirrors.kernel.org/archlinux/$repo/os/$arch'
arch_hostname="archlinux"
arch_hostdomain="localdomain"
root_format="ext4"
hooks="base udev autodetect modconf block encrypt filesystems keyboard fsck"

encrypt_with_key=false

if [ "${encrypt_with_key}" = true ];
then
	use_existing_key=false
	key_path="/key_mnt/root.crypt.key"
	key_format="vfat"
	# Load vfat or ext4 regardless of what the key uses. Simpler to support either.
	modules="nls_cp437 vfat ext4"
fi

# Traps for signals.

finish()
{
	echo "Finished. Clean up..."
	umount /mnt/boot || true
	if [ "${encrypt_with_key}" = true ];
	then
		umount "${key_dir}" || true
	fi
	umount /mnt || true
	cryptsetup luksClose cryptroot || true
}

interrupt()
{
	echo "Script interrupted."
	exit 1
}

trap interrupt INT
trap finish EXIT

# Helpers.

print_help()
{
	if [ "${encrypt_with_key}" = true ];
	then
		echo "Usage: /bin/bash bootstrap.sh --disk=disk --name=name --key=/path/to/key.keyfile"
	else
		echo "Usage: /bin/bash bootstrap.sh --disk=disk --name=name"
	fi
	echo
	echo "     --disk       Required. The disk on which to install Arch."
	echo "                  e.g. --disk=/dev/sda"
	echo
	echo "     --name       Required. The name of the initial user."
	echo "                  e.g. --name=will"
	if [ "${encrypt_with_key}" = true ];
	then
		echo
		echo "     --key        Optional. Path to an existing key file. This should"
		echo "                  be a path to a mounted, persistent, file. The script"
		echo "                  can then infer the partition id and other info."
		echo "                  e.g. --key=/some/mnt/some.keyfile"
		echo
	fi
	exit 1
}

############
# 0. Input #
############

if [ $# -lt 1 ];
then
	print_help
	exit 1
fi

while [ $# -gt 0 ]; do
	case "$1" in
		--disk=*)
			disk="${1#*=}"
			boot_part=${disk}1
			key_part=${disk}2
			root_part=${disk}3
			;;
		--name=*)
			username="${1#*=}"
			;;
		--key=*)
			use_existing_key=true
			key_path="${1#*=}"
			;;
		*)
			print_help
			exit 1
	esac
	shift
done

if [ "${encrypt_with_key}" = true ];
then
	key_dir=`dirname ${key_path}`
	mkdir -p "${key_dir}"
fi

if [ -z "${username}" ];
then
	echo "Must pass --name"
	echo
	print_help
	echo
	exit 1
fi

if [ -z "${disk}" ];
then
	echo "Must pass --disk"
	echo
	print_help
	echo
	exit 1
fi

############
# 1. Disks #
############

# Crude method for wiping out partition tables.
# dd if=/dev/zero of=${disk} bs=1M count=100
wipefs -a ${disk}
echo "o\nw\n" | sudo fdisk ${disk}

parted --script ${disk} mklabel msdos

# Create boot partition 1GB large.
echo -e "o\nn\np\n1\n\n+1000M\nw" | fdisk ${disk}
sleep 3

if [ "${encrypt_with_key}" = true ];
then
	# Create key partition 10MB large (we may not use this, but it is tiny).
	echo -e "n\np\n2\n\n+10M\nw" | fdisk ${disk}
	sleep 3
fi

# Create root partition using remaining space.
echo -e "n\np\n3\n\n\nw" | fdisk ${disk}
sleep 3

# Make boot partition bootable.
echo -e "a\n1\nw" | fdisk ${disk}
sleep 3
parted -s -a none ${disk} set 1 boot on

# Format boot partition.
mkfs.${root_format} -F ${boot_part}

if [ "${encrypt_with_key}" = true ];
then
	# Create a tiny partition for the key file (we may not use this, but it is tiny).
	mkfs.${key_format} ${key_part}
fi

############################################
# 2. Create key, or validate existing key  #
############################################

if [ "${encrypt_with_key}" = true ];
then
	# The user specified a path to an existing key.
	if [ "${use_existing_key}" = true ];
	then
		# Does the specified key exist?
		if [ ! -f "${key_path}" ];
		then
			echo "Existing key file not found"
			exit 1
		fi
	else
		# The user did not specify a key, so we will make one.
		mount ${key_part} "${key_dir}"
		# Generate random key.
		dd if=/dev/urandom bs=512 count=24 | tr -dc _A-Z-a-z-0-9 | head -c 4096 | dd of="${key_path}"
	fi
fi

###################
# 3. Encrypt root #
###################

if [ "${encrypt_with_key}" = true ];
then
	# Encrypt and format root partition.
	cryptsetup --batch-mode -y -v luksFormat ${root_part} "${key_path}"
	cryptsetup open ${root_part} cryptroot --key-file="${key_path}"
	mkfs.${root_format} -F /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
else
	# Encrypt and format root partition.
	cryptsetup -v luksFormat ${root_part}
	cryptsetup open ${root_part} cryptroot
	mkfs.${root_format} -F /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
fi

mkdir /mnt/boot
mount ${boot_part} /mnt/boot

######################################
# 4. Base system install and config  #
######################################

# Set our mirror.
echo "Server = ${mirror}" > /etc/pacman.d/mirrorlist

# Install system.
pacstrap /mnt base linux linux-firmware

genfstab -U -p /mnt >> /mnt/etc/fstab

# Hook for encryption.
sed -i -e "s|^HOOKS=.*|HOOKS=\(${hooks}\)|" /mnt/etc/mkinitcpio.conf
# Need to load specific modules to support our key disk at boot.
sed -i -e "s|^MODULES=.*|MODULES=\(${modules}\)|" /mnt/etc/mkinitcpio.conf

# Hostname.
arch-chroot /mnt /bin/bash -c "hostnamectl set-hostname ${arch_hostname}"
cat << EOF > /mnt/etc/hosts
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1        ${arch_hostname}
::1              ${arch_hostname}
127.0.1.1        ${arch_hostname}.${arch_hostdomain}    ${arch_hostname}
EOF

# Timezone.
arch-chroot /mnt ln -sf ${timezone} /etc/localtime

# Apps to install.
arch-chroot /mnt /bin/bash -c "pacman -S --noconfirm ${applications}"

# Enable DHCP.
arch-chroot /mnt systemctl enable dhcpcd
# Send the hostname when registering with DHCP.
echo "hostname" >> /mnt/etc/dhcpcd.conf

# Locale.
echo "${locale_gen}" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "${locale_conf}" > /mnt/etc/locale.conf
arch-chroot /mnt locale-gen

# Sudoers config.
arch-chroot /mnt pacman -S --noconfirm sudo
echo "root    ALL=(ALL) ALL" > /mnt/etc/sudoers
echo "%sudo   ALL=(ALL) ALL" >> /mnt/etc/sudoers
arch-chroot /mnt groupadd sudo
arch-chroot /mnt chmod 440 /etc/sudoers

# Add initial user.
arch-chroot /mnt useradd -m -s /bin/zsh -G sudo ${username}

# Blank out the root password. Sudo will be the only way to get root access!!!
arch-chroot /mnt passwd -l root

arch-chroot /mnt pacman -S --noconfirm firewalld
arch-chroot /mnt systemctl enable firewalld

##################
# 5. Boot Loader #
##################

if [ "${encrypt_with_key}" = true ];
then
	arch-chroot /mnt mkinitcpio -p linux

	root_part_uuid="$(blkid -s UUID -o value ${root_part})"
	key_mount=$(stat -c %m -- "${key_path}")
	key_relative_path=$(echo ${key_path}|sed "s|^${key_mount}||")
	key_part_dev=$(df -P "${key_mount}" | tail -1 | cut -d' ' -f 1)
	key_part_uuid=$(blkid -s UUID -o value ${key_part_dev})

	# TODO WFH Not supporting keys at the moment.
	# grub_cmdline_linux+=" cryptkey=UUID=${key_part_uuid}:${key_format}:${key_relative_path}"
else
	arch-chroot /mnt mkinitcpio -p linux

	root_part_uuid="$(blkid -s UUID -o value ${root_part})"
fi

mkdir /mnt/boot/extlinux
extlinux --install /mnt/boot/extlinux
cp /usr/lib/syslinux/bios/* /mnt/boot/extlinux/

cat <<EOF> /mnt/boot/extlinux/extlinux.conf
UI menu.c32

DEFAULT arch
PROMPT 0
MENU TITLE Boot Menu
TIMEOUT 50

LABEL arch
	MENU LABEL Arch Linux
	LINUX ../vmlinuz-linux
	APPEND root=/dev/mapper/cryptroot cryptdevice=UUID=${root_part_uuid}:cryptroot rw
	INITRD ../initramfs-linux.img

LABEL archfallback
	MENU LABEL Arch Linux Fallback
	LINUX ../vmlinuz-linux
	APPEND root=/dev/mapper/cryptroot cryptdevice=UUID=${root_part_uuid}:cryptroot rw
	INITRD ../initramfs-linux-fallback.img
EOF

########################
# 5. Set user password #
########################

clear

echo
echo "************************************************"
echo "You *must* set a password for user: ${username}"
echo "This is the only user who will have access."
echo
echo "If this fails, run manually."
echo "arch-chroot /mnt passwd ${username}"
echo
echo "************************************************"
echo

arch-chroot /mnt passwd ${username}

echo
echo "Done. Please reboot."

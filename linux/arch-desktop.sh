#!/usr/bin/env bash

set -e

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cat << EOF >> /etc/pacman.conf

[multilib]
Include = /etc/pacman.d/mirrorlist

EOF

pacman --needed -Sy \
	firefox chromium `# Browsers` \
	lightdm lightdm-gtk-greeter `# Display manager` \
	noto-fonts noto-fonts-emoji ttf-dejavu `# Fonts` \
	vim `# Text editing` \
	feh mpv libheif `# Multimedia` \
	thunar thunar-archive-plugin file-roller tumbler ffmpegthumbnailer `# File viewers` \
	xf86-video-vesa xorg-server xf86-video-intel xorg-xinit `# X11 drivers` \
	xclip xterm numlockx xcompmgr xbindkeys xdotool xautolock xorg-xbacklight xorg-xmodmap `# Core X11 utilities` \
	scrot `# Screenshotting` \
	i3-wm i3status i3lock rofi `# Window manager and related utilties` \
	udisks2 udiskie `# Media auto-mounting` \
	gnome-keyring seahorse `# GPG essentials for a desktop environment` \
	jack2 alsa-utils alsa-firmware pipewire-alsa wireplumber lib32-pipewire pipewire-pulse `# Audio. Would be nice to not need pulse/pipewire, but last time troubleshooting an install I needed them for Firefox and even had to reinstall Firefox` \
	alacritty `# Terminal` \
	rsync `# File copying` \
	zsh `# Next generation shell` \
	ufw `# Firewall` \
	ncdu `# Advanced disk-usage UI` \
	linux-headers base-devel curl git docker sudo less `# Development` \
	qemu-base tigervnc `# Virtual machines` \
	man-db

systemctl enable ufw dhcpcd iwd ntpd lightdm
ufw enable
ufw default deny

pushd "${script_dir}"
	cp -a ./etc/skel/. /etc/skel/

	install -Dm 0644 ./usr/share/applications/*.desktop /usr/share/applications

	install -Dm 0644 ./etc/modprobe.d/blacklist.conf "/etc/modprobe.d/blacklist.conf"

	install -Dm 0644 ./etc/ssh/sshd_config "/etc/ssh/sshd_config"

	install -Dm 0644 ./etc/ntp.conf "/etc/ntp.conf"

	install -dm 0750 "/etc/sudoers.d"
	install -Dm 0500 ./etc/sudoers.d/01_sudo "/etc/sudoers.d/01_sudo"

	install -Dm 0644 ./etc/locale.conf "/etc/locale.conf"
	install -Dm 0644 ./etc/locale.gen "/etc/locale.gen"
popd

ln -sf "/usr/share/zoneinfo/US/Central" /etc/localtime
locale-gen

groupadd sudo || true
groupadd aur || true
groupadd ssh || true

useradd --create-home --shell /usr/bin/zsh -G audio,docker,aur,sudo,ssh will
passwd will && passwd -l root

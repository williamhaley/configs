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
	thunar thunar-archive-plugin file-roller tumbler ffmpegthumbnailer gvfs gvfs-mtp `# File viewers` \
	xf86-video-vesa xorg-server xf86-video-intel xorg-xinit `# X11 drivers` \
	xclip xterm numlockx xcompmgr xbindkeys xdotool xautolock xorg-xbacklight xorg-xmodmap `# Core X11 utilities` \
	scrot `# Screenshotting` \
	i3-wm i3status i3lock rofi `# Window manager and related utilties` \
	udisks2 udiskie `# Media auto-mounting` \
	gnome-keyring seahorse `# GPG essentials for a desktop environment` \
	lxqt-policykit `# GUI polkit authentication agent` \
	jack2 alsa-utils alsa-firmware pipewire-alsa wireplumber lib32-pipewire pipewire-pulse `# Audio. Would be nice to not need pulse/pipewire, but last time troubleshooting an install I needed them for Firefox and even had to reinstall Firefox` \
	alacritty `# Terminal` \
	rsync `# File copying` \
	zsh `# Next generation shell` \
	ufw `# Firewall` \
	ncdu `# Advanced disk-usage UI` \
	linux-headers base-devel curl git docker docker-compose docker-buildx sudo less `# Development` \
	qemu-base tigervnc qemu-ui-gtk qemu-audio-pipewire `# Virtual machines` \
	man-db tmux exa `# system utilities` \
	rednotebook `# Journaling`

systemctl enable ufw dhcpcd iwd ntpd lightdm
ufw enable
ufw default deny

pushd "${script_dir}"
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
groupadd ssh || true

# Wheel is used by polkit at the least. Possibly by other frameworks and applications.
useradd --create-home --shell /usr/bin/zsh -G audio,docker,sudo,ssh,wheel will
passwd will && passwd -l root

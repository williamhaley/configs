# Overview

This repo contains my config files, aliases, zsh/bash/shell helpers, etc.

Various application config files can be copied manually as needed.

# Install

Run this to set up aliases, symlinks, copy config files into place, etc.

```
./install
```

# Linux

Configurations and standard scripts for settings up a new Linux machine. Lately I'm using Arch Linux and so this is tailored to that.

I'm steering away from `yay` and other AUR helpers. It's too easy to install potentially dangerous software. I'd rather manually download a binary or build something by hand and use mainline packages.

```
curl -O https://raw.githubusercontent.com/williamhaley/configs/main/linux/arch-install.sh
bash arch-install.sh /dev/sdX "my encryption password"
```

Create a user with an optional custom shell and additional groups.

```
useradd --create-home --shell /usr/bin/zsh -G docker,aur,sudo,ssh will
passwd will
```

Install the core apps I want.

```
pacman --needed -Sy \
	firefox chromium `# Browsers` \
	lightdm lightdm-gtk-greeter `# Display manager` \
	noto-fonts noto-fonts-emoji ttf-dejavu `# Fonts` \
	vim `# Text editing` \
	feh mpv libheif `# Multimedia` \
	thunar thunar-archive-plugin file-roller tumbler ffmpegthumbnailer `# File viewers` \
	xf86-video-vesa xorg-server xf86-video-intel xorg-xinit `# X11 drivers` \
	xclip  xterm numlockx xcompmgr xbindkeys xdotool xautolock `# Core X11 utilities` \
	scrot `# Screenshotting` \
	i3-wm i3status i3lock rofi `# Window manager and related utilties` \
	udisks2 udiskie `# Media auto-mounting` \
	gnome-keyring seahorse `# GPG essentials for a desktop environment` \
	jack2 alsa-utils `# Audio` \
	alacritty `# Terminal` \
	rsync `# File copying` \
	zsh `# Next generation shell` \
	ufw `# Firewall` \
	ncdu `# Advanced disk-usage UI` \
	linux-headers base-devel curl git docker `# Development` \
	qemu tigervnc `# Virtual machines`
```

May install some hardware-specific drivers/firmware.

```
sudo pacman --needed -S broadcom-wl-dkms
```

Blank out the root password once `sudo` is working properly for the user.

```
passwd -l root
```

Enable services.

```
sudo systemctl enable ufw dhcpcd iwd ntpd lightdm
```

Run a script for some customizations.

```
./linux/configure.sh
```

Add my user to necessary additional groups.

```
sudo usermod -a -G audio,docker,ssh,sudo will
```

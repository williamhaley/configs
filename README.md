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
ENCRYPTION_PASSWORD="my encryption password" bash arch-install.sh /dev/sdX
```

When the system is up and running a full "normal" desktop suite can be configured like so.

```
git clone https://github.com/williamhaley/configs.git
bash configs/linux/arch-desktop.sh
```

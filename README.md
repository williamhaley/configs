# Overview

This repo contains my config files, aliases, zsh/bash/shell helpers, etc.

Various application config files can be copied manually as needed.

# Install

Run this to set up aliases, symlinks, copy config files into place, etc.

```
./install
```

# Linux

Configurations and standard scripts for settings up a new Linux machine.

For the past 10 or so years I've been using Arch Linux as my default. I started with Knoppix and SUSE at university before moving on to Debian and Ubuntu along with TinyCore, DSL, Alpine, and a few other systems I've forgotten along the way.

I find Arch strikes a nice balance of simplicity, control, and support.

```
curl -O https://raw.githubusercontent.com/williamhaley/configs/main/linux/arch-install.sh
bash arch-install.sh /dev/sdX
```

When the system is up and running my standard desktop suite can be configured like so.

```
git clone https://github.com/williamhaley/configs.git
bash configs/linux/arch-desktop.sh
```

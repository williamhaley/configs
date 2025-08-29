#!/usr/bin/env bash
#
# I used to use dotbot. I tried to symlink all of my `X/.*` files into the root of ~. I guess I made a mistake somewhere because `./install` ended up deleting every dot file and directory in my $HOME directory. Never again.

set -e

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$(uname)" = "Linux" ]
then
  ln -sf "${script_dir}/X/mimeapps.list" ~/.config/mimeapps.list
  # (deprecated) for backwards compatibility https://wiki.archlinux.org/title/XDG_MIME_Applications#mimeapps.list
  ln -sf "${script_dir}/X/mimeapps.list" ~/.local/share/applications/mimeapps.list:

  ln -sf "${script_dir}/cmus/rc" ~/.config/cmus/rc

  ln -sf "${script_dir}/i3" ~/.config/i3

  #ln -sf "${script_dir}/X/.xbindkeysrc" ~/.xbindkeysrc
  #ln -sf "${script_dir}/X/.Xmodmap" ~/.Xmodmap
  #ln -sf "${script_dir}/X/.xprofile" ~/.xprofile
  #ln -sf "${script_dir}/X/.Xresources" ~/.Xresources
fi

ln -sf "${script_dir}/alacritty" ~/.config/alacritty
ln -sf "${script_dir}/direnv" ~/.config/direnv
ln -sf "${script_dir}/git/gitconfig" ~/.gitconfig
ln -sf "${script_dir}/ssh/config" ~/.ssh/config
ln -sf "${script_dir}/tmux/tmux.conf" ~/.tmux.conf
ln -sf "${script_dir}/vim/vimrc" ~/.vimrc
ln -sf "${script_dir}/zsh/zshenv" ~/.zshenv
ln -sf "${script_dir}/zsh/zshrc" ~/.zshrc

mkdir -p -m 0700 ~/.ssh

mkdir -p ~/bin
mkdir -p ~/src
mkdir -p ~/Downloads

echo "done"

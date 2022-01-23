#!/bin/sh

# Script that will automatically change the background image
background.sh -l &

# Arrange monitors
xrandr --output HDMI-0 --left-of VGA-0
xrandr --output HDMI-0 --primary

VBoxClient-all &

# Set up custom key modifiers (Caps Lock as ESC for example)
xmodmap ~/.Xmodmap

# Set up custom key bindings
xbindkeys -p &

numlockx &
eval $(ssh-agent)
xrdb ~/.Xresources

# Start udiskie for simpler USB storage device mounting
udiskie -t &

# Start the i3 window manager
exec i3


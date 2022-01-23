#!/usr/bin/env bash

set -e

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

if command -v ip > /dev/null;
then
	gateway=$(ip route | grep default | awk '{print $3}')
else
	gateway=$(route -n get default | grep gateway | awk '{print $2}')
fi

nmap -sn -oN - ${gateway}/24 | sed 's|MAC\(.*\)|  * MAC\1|g' | sed 's|Host\(.*\)|  * Host\1|g'


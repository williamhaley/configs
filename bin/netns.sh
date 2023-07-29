#!/usr/bin/env bash

set -e

namespace="testing"
user=will
device="wlx00c0caae78c7"
network="att-wifi"

namespace_bash()
{
	sudo ip netns exec "${namespace}" su "${user}" -c bash
}

namespace_ps()
{
	ps $(ip netns pids "${namespace}")
}

namespace_start()
{
	if ! find /var/run/netns -type f -name "${namespace}" > /dev/null
	then
		sudo ip netns add "${namespace}"
	fi
	if [ -L "/sys/class/net/${device}" ]
	then
		phys="$(basename "$(readlink "/sys/class/net/${device}/phy80211")")"
		sudo iw phy "${phys}" set netns "$(sudo ip netns exec "${namespace}" sh -c 'sleep 1 >&- & echo "$!"')"
  	fi

	sudo ip netns exec "${namespace}" bash -s -<<EOF
	set -xe
	ip link set dev lo up
	ip link set dev "${device}" up
	sudo iw dev "${device}" connect "${network}" || true
	sudo dhclient "${device}"
	ip addr
EOF
}

namespace_status()
{
	if ip -f inet addr show "${device}" 2> /dev/null
	then
		echo "device not in namespace"
		exit 1
	fi
	if ! find /var/run/netns -type f -name "${namespace}" > /dev/null
	then
		echo "namespace not created"
		exit 1
	fi
	if ! sudo ip netns exec "${namespace}" ip -f inet addr show "${device}"	&> /dev/null
	then
		echo "device not in namespace"
		exit 1
	fi
	echo "running"
}

namespace_chromium()
{
	sudo ip netns exec "${namespace}" chromium-browser --user-data-dir=/tmp/new --new-window --incognito --proxy-server="socks5://127.0.0.1:9050" --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" https://check.torproject.org
}

namespace_$@


#!/usr/bin/env bash

set -e

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# sudo cp "${script_dir}/desktop/"*.desktop /usr/share/applications/

pushd "${script_dir}"
	sudo install -Dm 0644 ./usr/share/applications/*.desktop /usr/share/applications

	sudo install -Dm 0644 ./etc/ssh/sshd_config "/etc/ssh/sshd_config"

	sudo install -Dm 0644 ./etc/ntp.conf "/etc/ntp.conf"

	sudo install -dm 0750 "/etc/sudoers.d"
	sudo install -Dm 0500 ./etc/sudoers.d/01_sudo "/etc/sudoers.d/01_sudo"

	sudo install -Dm 0644 ./etc/locale.conf "/etc/locale.conf"
	sudo install -Dm 0644 ./etc/locale.gen "/etc/locale.gen"
popd

sudo ln -sf "/usr/share/zoneinfo/US/Central" /etc/localtime
sudo locale-gen

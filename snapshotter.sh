#!/bin/bash

if [[ $(id -u) != 0 ]]; then
	echo 'Run as root'
	exit 1
fi

if ! which btrfs &> /dev/null; then
	echo 'Install btrfs-progs'
	exit 1
fi

CONFIG="$(dirname "$0")/subvolumes.conf"
SNAPSHOTS_PATH="snapshotter"

umount_device() {
	umount "$MOUNT_DIR"
	is_mounted=0
}

mount_device() {
	local device="$1"
	[[ $is_mounted == 1 ]] && umount_device
	mount -t btrfs -osubvol=/ "$device" "$MOUNT_DIR" &> /dev/null && is_mounted=1
}

exec_config() {
	local MOUNT_DIR="$(mktemp -d)"

	while read line; do
		if [[ "${line:0:1}" == "-" ]]; then
			[[ $is_mounted == 0 ]] && continue
			local path="${line:1}"
			echo "PATH: $path"
		else
			mount_device "$line"
			[[ $is_mounted == 0 ]] && continue
			echo "DEVICE: $line"
			ls "$MOUNT_DIR"
		fi
	done < "$CONFIG"

	[[ $is_mounted == 1 ]] && umount_device
	rm -r "$MOUNT_DIR"
}

exec_config

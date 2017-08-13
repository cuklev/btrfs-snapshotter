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
	local time="$(date "+%Y.%m.%d-%H.%M.%S")"

	while read line; do
		if [[ "${line:0:1}" == "-" ]]; then
			[[ $is_mounted == 0 ]] && continue
			local subvolume="${line:1}"
			local sv_path="$MOUNT_DIR/$subvolume"
			local sn_path="$MOUNT_DIR/$SNAPSHOTS_PATH/$time/$subvolume"
			mkdir -p "$MOUNT_DIR/$SNAPSHOTS_PATH/$time/$(dirname "$subvolume")"
			btrfs subvolume snapshot "$sv_path" "$sn_path"
		else
			mount_device "$line"
		fi
	done < "$CONFIG"

	[[ $is_mounted == 1 ]] && umount_device
	rm -r "$MOUNT_DIR"
}

exec_config

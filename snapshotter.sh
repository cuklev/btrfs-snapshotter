#!/bin/bash

if [[ $(id -u) != 0 ]]; then
	echo 'Run as root'
	exit 1
fi

if ! which btrfs &> /dev/null; then
	echo 'Install btrfs-progs'
	exit 1
fi

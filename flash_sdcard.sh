#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: flash_sdcard.sh <device>"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

dd if=./build/rootfs.img of="$1" status=progress iflag=direct oflag=direct bs=10M

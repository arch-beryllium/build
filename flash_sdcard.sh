#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: flash_sdcard.sh <image name> <device>"
  echo "Image names: phosh, plasma-mobile"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

dd if="./build/rootfs-$1.img" of="$2" status=progress iflag=direct oflag=direct bs=10M

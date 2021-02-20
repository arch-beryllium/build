#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: flash_sdcard.sh <image name> <device>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

dd if="./build/$1-rootfs.img" of="$2" status=progress iflag=direct oflag=direct bs=10M

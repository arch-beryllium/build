#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: flash_boot.sh <image name>"
  echo "Image names: barebone, phosh, plasma-mobile"
  exit 1
fi

fastboot flash boot "build/$1-boot.img"
fastboot reboot

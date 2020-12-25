#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: flash_sdcard.sh <image name>"
  echo "Image names: phosh, plasma-mobile"
  exit 1
fi

fastboot boot "build/boot-$1.img"

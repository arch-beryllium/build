#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: build_and_flash_sdcard.sh <image name> <device>"
  echo "Image names: barebone, phosh, plasma-mobile"
  exit 1
fi

source build.sh "$1"
source flash_sdcard.sh "${1//-apps/}" "$2"

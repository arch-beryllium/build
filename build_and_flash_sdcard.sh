#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: build_and_flash_sdcard.sh <device>"
  exit 1
fi

source build.sh
source flash_sdcard.sh "$1"

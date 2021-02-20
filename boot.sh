#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: boot.sh <image name>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

fastboot boot "build/$1-boot.img"

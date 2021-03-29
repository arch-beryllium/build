#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: boot.sh <image name> <panel type>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  echo "Panel types: tianma, ebbg"
  exit 1
fi

fastboot boot "build/$1-boot-$2.img"

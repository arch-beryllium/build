#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: make_installer.sh <image name> <panel type>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  echo "Panel types: tianma, ebbg"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

cd installer
NO_PMB=1 ./makeinstaller.sh -a -p sda21 -c "../build/$1-boot-$2.img" -i "../build/$1-rootfs-minimal.img" -u "$1" -d beryllium -o "ALARM" -v rolling -b "$(realpath "../build/$1-installer-$2.zip")"

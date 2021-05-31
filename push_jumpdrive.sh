#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: push_jumpdrive.sh <image name> <device>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

mount "$2" /mnt
cleanup() {
  umount /mnt -lc || true
}
trap cleanup EXIT
mkdir -p /mnt/.stowaways
pv "./build/$1-rootfs-minimal.img" >/mnt/.stowaways/ALARM.img

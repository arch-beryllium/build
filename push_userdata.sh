#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: push_userdata.sh <image name>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

adb push "./build/$1-rootfs-minimal.img" /data/.stowaways/ALARM.img
adb shell e2fsck -fy /data/.stowaways/ALARM.img
adb shell resize2fs /data/.stowaways/ALARM.img 16G

#!/bin/bash
set -e

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -x

DEVICE=$(df -P "$0" | tail -1 | cut -d' ' -f 1 | sed 's/..$//')
PART="1"

resize() {
  start=$(fdisk -l "${DEVICE}" | grep "${DEVICE}"p${PART} | sed 's/*//' | awk '{print $2}')

  set +e
  fdisk "${DEVICE}" <<EOF
p
d
$PART
n
p
$PART
$start

a
$PART
w
EOF
  set -e

  partx -u "${DEVICE}"
  resize2fs "${DEVICE}"p${PART}
}

resize

rm /usr/local/sbin/resize_rootfs.sh
rm /usr/lib/systemd/system/resize_rootfs.service
rm /usr/lib/systemd/system/multi-user.target.wants/resize_rootfs.service

echo "Done!"

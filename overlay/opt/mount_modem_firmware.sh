#!/bin/bash
# Copied from https://gitlab.com/postmarketOS/pmaports/-/blob/master/device/testing/firmware-motorola-potter/moto-modem-rfs-setup.openrc

MODEM_FIRMWARE_DIR="/lib/firmware/persist"
# The firmware present here is unique to each device
# Using the firmware of one device on another can will simply fail
# This is needed because motorola devices derive IMEI and other unique
# IDs from these files
# See also: https://forum.xda-developers.com/g5-plus/how-to/fix-persist-resolve-imei0-explanation-t3825147

if [ ! -d $MODEM_FIRMWARE_DIR ]; then
  # Make a copy of the firmware if its not already made
  # Use the copy instead of the original, because if due to some error
  # somehow the firmware gets corrupted, the original firmware will
  # still be available on the 'persist' partition

  PERSIST_PATH="/tmp/persist"
  PERSIST_DEV="/dev/disk/by-partlabel/persist"

  mkdir -p $PERSIST_PATH
  mount $PERSIST_DEV -o ro,noatime $PERSIST_PATH

  mkdir $MODEM_FIRMWARE_DIR

  cp -R "$PERSIST_PATH"/rfs/msm/mpss/ "$MODEM_FIRMWARE_DIR"/readwrite

  umount $PERSIST_DEV
  rmdir $PERSIST_PATH
fi

ln -sf "$MODEM_FIRMWARE_DIR"/readwrite /tmp/tqftpserv

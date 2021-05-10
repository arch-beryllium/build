#!/usr/bin/ash

run_hook() {
  if [ -e /sys/devices/platform/bootsplash.0/enabled ]; then
    echo 0 >/sys/devices/platform/bootsplash.0/enabled
  fi

  # shellcheck disable=SC2154
  device=$(resolve_device "$root")
  e2fsck -fy "${device}"
  resize2fs "${device}"

  if [ -e /sys/devices/platform/bootsplash.0/enabled ]; then
    echo 1 >/sys/devices/platform/bootsplash.0/enabled
  fi
}

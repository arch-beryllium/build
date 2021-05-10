#!/usr/bin/ash

run_hook() {
  if [ -e "/dev/disk/by-label/ALARM" ]; then
    export root="/dev/disk/by-label/ALARM"
  else
    mkdir -p /mnt
    mount "/dev/sda21" /mnt
    for path in /mnt/.stowaways /mnt /mnt/media/0; do
      if [ -f "$path/ALARM.img" ]; then
        loop_device=$(losetup -f)
        losetup -P "$loop_device" "$path/ALARM.img"
        export root="${loop_device}"
        break
      fi
    done
  fi
}

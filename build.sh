#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: build.sh <target>"
  echo "Targets: barebone, phosh, phosh-apps, phosh-bootimg, plasma-mobile, plasma-mobile-apps, plasma-mobile-bootimg, lomiri, lomiri-apps, lomiri-bootimg"
  exit 1
fi

if [ "$1" = "barebone" ]; then
  IMAGE_NAME="barebone"

elif [ "$1" = "barebone-bootimg" ]; then
  IMAGE_NAME="barebone"
  ONLY_BOOTIMG=1

elif [ "$1" = "phosh" ]; then
  IMAGE_NAME="phosh"

elif [ "$1" = "phosh-apps" ]; then
  IMAGE_NAME="phosh"
  INCLUDE_APPS=1

elif [ "$1" = "phosh-bootimg" ]; then
  IMAGE_NAME="phosh"
  ONLY_BOOTIMG=1

elif [ "$1" = "plasma-mobile" ]; then
  IMAGE_NAME="plasma-mobile"

elif [ "$1" = "plasma-mobile-apps" ]; then
  IMAGE_NAME="plasma-mobile"
  INCLUDE_APPS=1

elif [ "$1" = "plasma-mobile-bootimg" ]; then
  IMAGE_NAME="plasma-mobile"
  ONLY_BOOTIMG=1

elif [ "$1" = "lomiri" ]; then
  IMAGE_NAME="lomiri"

elif [ "$1" = "lomiri-apps" ]; then
  IMAGE_NAME="lomiri"
  INCLUDE_APPS=1

elif [ "$1" = "lomiri-bootimg" ]; then
  IMAGE_NAME="lomiri"
  ONLY_BOOTIMG=1

else
  echo "Unknown target: $*"
  exit 1
fi

EXTRA_INSTALL_PACKAGES=()
EXTRA_UNINSTALL_PACKAGES=()
if [ "$IMAGE_NAME" != "barebone" ]; then
  EXTRA_INSTALL_PACKAGES+=("ui-$IMAGE_NAME-meta" "tweaks-$IMAGE_NAME" "tweaks-desktop-files" "bootsplash")
fi
if [ -n "$INCLUDE_APPS" ]; then
  EXTRA_INSTALL_PACKAGES+=("apps-$IMAGE_NAME-meta")
  EXTRA_UNINSTALL_PACKAGES+=("apps-$IMAGE_NAME-meta")
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

ROOTFS="http://de4.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
TARBALL="build/$(basename $ROOTFS)"
DEST=$(mktemp -d)
LOOP_DEVICE=$(losetup -f)
ROOTFSIMG="build/$IMAGE_NAME-rootfs.img"

mkdir -p build

unmount() {
  if [ -e "$DEST/proc" ] && mountpoint "$DEST/proc" >/dev/null; then
    umount "$DEST/proc" || true
  fi
  if [ -e "$DEST/sys" ] && mountpoint "$DEST/sys" >/dev/null; then
    umount "$DEST/sys" || true
  fi
  if [ -e "$DEST/dev" ] && mountpoint "$DEST/dev" >/dev/null; then
    umount "$DEST/dev" || true
  fi
  if [ -e "$DEST/tmp" ] && mountpoint "$DEST/tmp" >/dev/null; then
    umount "$DEST/tmp" || true
  fi
  if [ -e "$DEST" ] && mountpoint "$DEST" >/dev/null; then
    umount -lc "$DEST" || true
  fi
  if [ -e "$DEST" ]; then
    rm -rf "$DEST" || true
  fi
}

function destroy_loop_device() {
  if losetup -l | grep -q "$LOOP_DEVICE"; then
    losetup -d "$LOOP_DEVICE" || true
  fi
}

cleanup() {
  unmount
  destroy_loop_device
}
trap cleanup EXIT

do_chroot() {
  cmd="$*"
  cp "$(which qemu-aarch64-static)" "$DEST/usr/bin"
  mount -o bind /dev "$DEST/dev"
  chroot "$DEST" mount -t proc proc /proc || true
  chroot "$DEST" mount -t sysfs sys /sys || true
  chroot "$DEST" mount -t tmpfs none /tmp || true
  chroot "$DEST" mount -t tmpfs none /var/cache/pacman/pkg || true
  chroot "$DEST" "$cmd"
  chroot "$DEST" umount /var/cache/pacman/pkg || true
  chroot "$DEST" umount /tmp || true
  chroot "$DEST" umount /sys || true
  chroot "$DEST" umount /proc || true
  umount "$DEST/dev" || true
  rm -rf "$DEST/usr/bin/qemu-aarch64-static"
}

set -ex

function download_sources() {
  if [ ! -f "$TARBALL" ]; then
    wget "$ROOTFS" -O "$TARBALL"
  fi
}

function setup_clean_rootfs() {
  rm -f "$ROOTFSIMG"
  fallocate -l 7G "$ROOTFSIMG"
  losetup -P "$LOOP_DEVICE" "$ROOTFSIMG"
  mkfs.ext4 -L ALARM "${LOOP_DEVICE}"
  mount "${LOOP_DEVICE}" "$DEST"
}

function setup_dirty_rootfs() {
  if [ ! -f "$ROOTFSIMG" ]; then
    echo "You need to already have built a rootfs to use it"
    echo "Run build_phosh.sh or build_plasma_mobile.sh first"
    exit 1
  fi
  losetup -P "$LOOP_DEVICE" "$ROOTFSIMG"
  mount "${LOOP_DEVICE}" "$DEST"
}

function build_rootfs() {
  tar --use-compress-program=pigz --same-owner -xpf "$TARBALL" -C "$DEST"

  cp pacman.conf "$DEST/etc/pacman.conf"

  if [ -n "$LOCAL_MIRROR" ]; then
    cp "$DEST/etc/pacman.conf" "$DEST/etc/pacman.conf.bak"
    cp "$DEST/etc/pacman.d/mirrorlist" "$DEST/etc/pacman.d/mirrorlist.bak"
    sed -i "s/Server = .*/Include = \/etc\/pacman\.d\/mirrorlist/" "$DEST/etc/pacman.conf"
    printf "Server = %s" "$LOCAL_MIRROR" >"$DEST/etc/pacman.d/mirrorlist"
  fi

  if [ "$IMAGE_NAME" != "barebone" ]; then
    sed -i 's/fsck)/fsck bootsplash)/' "$DEST/etc/mkinitcpio.conf"
  fi

  cat >"$DEST/install" <<EOF
#!/bin/bash
set -ex

pacman -Rdd --noconfirm linux-aarch64 # Don't upgrade kernel which we will remove later anyway
pacman -Syyu --noconfirm --needed --overwrite=* base base-beryllium $(printf " %s" "${EXTRA_INSTALL_PACKAGES[@]}")
if [ ${#EXTRA_UNINSTALL_PACKAGES[@]} -ne 0 ]; then
  pacman -Rdd --noconfirm $(printf " %s" "${EXTRA_UNINSTALL_PACKAGES[@]}")
fi

usermod -a -G network,video,audio,optical,storage,input,scanner,games,lp,rfkill,wheel alarm
echo "alarm:123456" | chpasswd

cp -r /etc/skel/. /home/alarm/
cp -r /etc/xdg/. /home/alarm/.config/
rm /home/alarm/.config/systemd/user # Broken symlink that's not needed

chown alarm:alarm /home/alarm/ -R

pacman -Q | cut -f 1 -d " " | sed "s/-git$//" > /packages
EOF
  chmod +x "$DEST/install"
  do_chroot /install
  rm "$DEST/install"

  mv "$DEST/packages" "build/$IMAGE_NAME-packages.txt"
}

function rebuild_kernel_ramdisk_bootimg() {
  cat >"$DEST/rebuild" <<EOF
#!/bin/bash
set -ex

pacman -Syu --noconfirm --overwrite=* \
  firmware-xiaomi-beryllium \
  linux-beryllium \
  linux-beryllium-headers
EOF
  chmod +x "$DEST/rebuild"
  do_chroot /rebuild
  rm "$DEST/rebuild"
}

function extract_kernel_ramdisk_bootimg() {
  cp "$DEST/boot/Image" "build/$IMAGE_NAME-Image"
  cp "$DEST/boot/initramfs-linux.img" "build/$IMAGE_NAME-initramfs.img"
  cp "$DEST/boot/boot-tianma.img" "build/$IMAGE_NAME-boot-tianma.img"
  cp "$DEST/boot/boot-ebbg.img" "build/$IMAGE_NAME-boot-ebbg.img"
}

function shrink_rootfs() {
  unmount
  e2fsck -fy "$LOOP_DEVICE"
  resize2fs -M "$LOOP_DEVICE"
  destroy_loop_device
  e2fsck -fy $ROOTFSIMG
  resize2fs -M $ROOTFSIMG
}

function setup_qemu() {
  # Remove current configuration
  if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    echo -1 >/proc/sys/fs/binfmt_misc/qemu-aarch64
  fi
  echo ':qemu-aarch64:M:0:\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:CF' >/proc/sys/fs/binfmt_misc/register
}

setup_qemu

if [ -n "$ONLY_BOOTIMG" ]; then
  setup_dirty_rootfs
  rebuild_kernel_ramdisk_bootimg
else
  download_sources
  setup_clean_rootfs
  build_rootfs
fi

extract_kernel_ramdisk_bootimg

shrink_rootfs

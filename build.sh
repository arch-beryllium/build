#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: build.sh <target>"
  echo "Targets: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

if [ "$1" = "barebone" ] || [ "$1" = "phosh" ] || [ "$1" = "plasma-mobile" ] || [ "$1" = "lomiri" ]; then
  IMAGE_NAME="$1"
else
  echo "Unknown target: $*"
  exit 1
fi

EXTRA_INSTALL_PACKAGES=()
if [ "$IMAGE_NAME" != "barebone" ]; then
  EXTRA_INSTALL_PACKAGES+=("ui-$IMAGE_NAME-meta" "tweaks-$IMAGE_NAME" "tweaks-desktop-files" "bootsplash")
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

DEST=$(mktemp -d)
TMP=$(mktemp -d)
ROOTFSIMG="build/$IMAGE_NAME-rootfs.img"
MINIMALROOTFSIMG="build/$IMAGE_NAME-rootfs-minimal.img"

mkdir -p build

cleanup() {
  if [ -e "$DEST" ] && mountpoint "$DEST" >/dev/null; then
    umount -lc "$DEST" || true
  fi
  if [ -e "$DEST" ]; then
    rm -rf "$DEST" || true
  fi
  if [ -e "$TMP" ]; then
    rm -rf "$TMP" || true
  fi
}
trap cleanup EXIT

function setup_rootfs() {
  if [ ! -f "$ROOTFSIMG" ]; then
    fallocate -l 5G "$ROOTFSIMG"
    mkfs.ext4 -L ALARM "$ROOTFSIMG"
  fi
  mount -o loop "$ROOTFSIMG" "$DEST"
}

function build_rootfs() {
  docker build -t archlinux:pacstrap - <src/Dockerfile

  cp src/pacman.conf "$TMP"
  echo "Server = http://mirror.archlinuxarm.org/\$arch/\$repo" >"$TMP"/mirrorlist

  if [ -n "$LOCAL_MIRROR" ]; then
    cp "$TMP/pacman.conf" "$TMP/pacman.conf.bak"
    cp "$TMP/mirrorlist" "$TMP/mirrorlist.bak"
    sed -i "s/Server = .*/Include = \/etc\/pacman\.d\/mirrorlist/" "$TMP/pacman.conf"
    printf "Server = %s" "$LOCAL_MIRROR" >"$TMP/mirrorlist"
  fi

  # shellcheck disable=SC2046
  docker run \
    --privileged --rm -it \
    -v "$TMP/pacman.conf":/etc/pacman.conf \
    -v "$TMP/mirrorlist":/etc/pacman.d/mirrorlist \
    -v "$DEST":/newroot:z \
    archlinux:pacstrap \
    pacstrap -c -G -M /newroot base base-beryllium $(printf " %s" "${EXTRA_INSTALL_PACKAGES[@]}") --needed

  cp "$TMP/pacman.conf"* "$DEST/etc/"
  cp "$TMP/mirrorlist"* "$DEST/etc/pacman.d/"

  docker run \
    --privileged --rm -i \
    -v "$DEST":/newroot:z \
    archlinux:pacstrap \
    arch-chroot /newroot <<EOF
if ! id -u "alarm" >/dev/null 2>&1; then
  useradd -m alarm
fi
usermod -a -G network,video,audio,optical,storage,input,scanner,games,lp,rfkill,wheel alarm
echo "alarm:123456" | chpasswd
chown alarm:alarm /home/alarm -R
EOF
}

function extract_kernel_ramdisk_bootimg() {
  cp "$DEST/boot/Image" "build/$IMAGE_NAME-Image"
  cp "$DEST/boot/initramfs-linux.img" "build/$IMAGE_NAME-initramfs.img"
  cp "$DEST/boot/boot-tianma.img" "build/$IMAGE_NAME-boot-tianma.img"
  cp "$DEST/boot/boot-ebbg.img" "build/$IMAGE_NAME-boot-ebbg.img"
}

function shrink_rootfs() {
  cp "$ROOTFSIMG" "$MINIMALROOTFSIMG"
  e2fsck -fy "$MINIMALROOTFSIMG"
  resize2fs -M "$MINIMALROOTFSIMG"
}

function setup_qemu() {
  # Remove current configuration
  if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    echo -1 >/proc/sys/fs/binfmt_misc/qemu-aarch64
  fi
  echo ':qemu-aarch64:M:0:\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:CF' >/proc/sys/fs/binfmt_misc/register
}

setup_qemu

setup_rootfs
build_rootfs
extract_kernel_ramdisk_bootimg

cleanup
shrink_rootfs

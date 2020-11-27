#!/bin/bash
if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export ROOTFS="https://github.com/dreemurrs-embedded/Pine64-Arch/releases/download/20201112/archlinux-pinephone-20201112.img.xz"
export BASEIMG="build/$(basename $ROOTFS | sed "s/\.xz//")"
export DEST=$(mktemp -d)
export LOOP_DEVICE=$(losetup -f)

mkdir -p build

cleanup() {
  if [ -e "$DEST/proc/cmdline" ]; then
    umount "$DEST/proc"
  fi
  if [ -d "$DEST/sys/kernel" ]; then
    umount "$DEST/sys"
  fi
  umount "$DEST/dev" || true
  umount "$DEST/tmp" || true

  umount -lc "$DEST"
  rm -rf "$DEST"

  losetup -d "$LOOP_DEVICE"
}
trap cleanup EXIT

do_chroot() {
  cmd="$*"
  mount -o bind /tmp "$DEST/tmp"
  mount -o bind /dev "$DEST/dev"
  chroot "$DEST" mount -t proc proc /proc || true
  chroot "$DEST" mount -t sysfs sys /sys || true
  chroot "$DEST" "$cmd"
  chroot "$DEST" umount /sys
  chroot "$DEST" umount /proc
  umount "$DEST/dev"
  umount "$DEST/tmp"
}

set -ex

function download_repo() {
  if [ ! -d "build/$1" ]; then
    git clone --depth=1 "$2" -b "$3" "build/$1"
  else
    (
      cd "build/$1" || exit 1
      git pull
    )
  fi
}

function download_sources() {
  download_repo "sdm845-linux" "https://gitlab.com/sdm845-mainline/sdm845-linux.git/" "beryllium-battery" &
  download_repo "firmware-xiaomi-beryllium" "https://gitlab.com/sdm845-mainline/firmware-xiaomi-beryllium.git/" "master" &
  download_repo "pmaports" "https://gitlab.com/postmarketOS/pmaports.git/" "master" &
  download_repo "efidroid-build" "https://github.com/efidroid/build.git" "master" &

  if [ ! -f "$BASEIMG" ]; then
    function download_baseimg() {
      wget "$ROOTFS" -O "$BASEIMG.xz"
      unxz "$BASEIMG.xz"
    }
    download_baseimg &
  fi

  wait
}

function setup_rootfsimg() {
  cp "$BASEIMG" "build/rootfs.img"
  dd if=/dev/zero bs=1M count=1024 >>"build/rootfs.img"
  growpart "build/rootfs.img" 1

  losetup -P "$LOOP_DEVICE" "build/rootfs.img"

  mkdir -p "$DEST"
  mount "${LOOP_DEVICE}"p1 "$DEST"
}

function build_rootfs() {
  rm -rf "$DEST/etc/resolv.conf"
  printf "nameserver 8.8.8.8\nnameserver 8.8.4.4" >"$DEST/etc/resolv.conf"

  sed -i "s/DT_MODEL=\$(< \/sys\/firmware\/devicetree\/base\/model)/DT_MODEL=\"PinePhone\"/" "$DEST/usr/local/sbin/first_time_setup.sh"

  cat >>"$DEST/etc/pacman.conf" <<EOF
[beryllium]
SigLevel = Never
Server = https://repo.lohl1kohl.de/beryllium/aarch64/
EOF

  cp on_device_scripts/install.sh "$DEST/install"
  chmod +x "$DEST/install"
  do_chroot /install
  rm "$DEST/install"

  cp build/firmware-xiaomi-beryllium/lib/firmware "$DEST/usr/lib" -r

  cp overlay/* "$DEST" -r
}

function build_kernel() {
  cd build/sdm845-linux || exit 1

  # Reset kernel config
  git checkout .

  # Patch kernel config
  sed -i "s/# CONFIG_DRM_FBDEV_EMULATION is not set/CONFIG_DRM_FBDEV_EMULATION=y/" arch/arm64/configs/beryllium_defconfig
  sed -i "s/CONFIG_CMDLINE_FORCE=y/CONFIG_CMDLINE_FORCE=n/" arch/arm64/configs/beryllium_defconfig
  cat >>arch/arm64/configs/beryllium_defconfig <<EOF

#USB drivers
CONFIG_USB_DWC2=y
EOF

  # Build kernel
  MAKEFLAGS="-j$(nproc --all)" make beryllium_defconfig Image.gz modules dtbs
  cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium.dtb >arch/arm64/boot/.Image.gz-dtb

  # Install kernel into rootfs
  mkdir -p "$DEST/boot" "$DEST/usr/lib/modules"
  export INSTALL_PATH="$DEST/boot"
  export INSTALL_MOD_PATH="$DEST/usr"
  make zinstall modules_install
}

function build_initramfs() {
  export KERNEL_RELEASE=$(cat build/sdm845-linux/include/config/kernel.release)

  cat >"$DEST/initramfs" <<EOF
#!/bin/bash
set -ex
mkinitcpio --generate /boot/initramfs-$KERNEL_RELEASE.img --kernel $KERNEL_RELEASE
EOF
  chmod +x "$DEST/initramfs"
  do_chroot /initramfs
  rm "$DEST/initramfs"

  mv "$DEST/boot/initramfs-$KERNEL_RELEASE.img" build/initramfs.img
}

function build_bootimg() {
  FILE=build/pmaports/device/testing/device-xiaomi-beryllium/deviceinfo
  python3 build/efidroid-build/tools/mkbootimg \
    --kernel build/sdm845-linux/arch/arm64/boot/.Image.gz-dtb \
    --ramdisk build/initramfs.img \
    --base "$(grep "offset_base" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --second_offset "$(grep "offset_second" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --kernel_offset "$(grep "offset_kernel" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --ramdisk_offset "$(grep "offset_ramdisk" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --tags_offset "$(grep "offset_tags" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --pagesize "$(grep "pagesize" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --cmdline "root=/dev/mmcblk0p1 rw" \
    -o build/boot.img
}

download_sources
setup_rootfsimg
build_rootfs &
build_kernel &
wait

build_initramfs
build_bootimg

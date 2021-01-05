#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: build.sh <target>"
  echo "Targets: barebone, phosh, plasma-mobile, phosh-apps, plasma-mobile-apps, phosh-bootimg, plasma-mobile-bootimg"
  exit 1
fi

if [ "$1" = "barebone" ]; then
  export IMAGE_NAME="barebone"
  export IMAGE_SIZE=2048

elif [ "$1" = "phosh" ]; then
  export IMAGE_NAME="phosh"
  export IMAGE_SIZE=3072

elif [ "$1" = "plasma-mobile" ]; then
  export IMAGE_NAME="plasma-mobile"
  export IMAGE_SIZE=5120

elif [ "$1" = "phosh-apps" ]; then
  export IMAGE_NAME="phosh"
  export INCLUDE_APPS=1
  export IMAGE_SIZE=4096

elif [ "$1" = "plasma-mobile-apps" ]; then
  export IMAGE_NAME="plasma-mobile"
  export INCLUDE_APPS=1
  export IMAGE_SIZE=5120

elif [ "$1" = "phosh-bootimg" ]; then
  export IMAGE_NAME="phosh"
  export ONLY_BOOTIMG=1

elif [ "$1" = "plasma-mobile-bootimg" ]; then
  export IMAGE_NAME="plasma-mobile"
  export ONLY_BOOTIMG=1

else
  echo "Unknown target: $*"
  exit 1
fi

IFS=$'\n' read -d '' -r -a base <$IMAGE_NAME/base
if [ -n "$INCLUDE_APPS" ]; then
  IFS=$'\n' read -d '' -r -a apps <$IMAGE_NAME/apps
fi
export EXTRA_PACKAGES=("${base[@]}" "${apps[@]}")
export PRE_SCRIPT=$(cat $IMAGE_NAME/pre-script.sh)
export POST_SCRIPT=$(cat $IMAGE_NAME/post-script.sh)

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

export ROOTFS="http://mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
export TARBALL="build/$(basename $ROOTFS)"
export DEST=$(mktemp -d)
export LOOP_DEVICE=$(losetup -f)
export ROOTFSIMG="build/$IMAGE_NAME-rootfs.img"

mkdir -p build

cleanup() {
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
  if [ -e "$LOOP_DEVICE"p1 ]; then
    losetup -d "$LOOP_DEVICE" || true
  fi
}
trap cleanup EXIT

do_chroot() {
  cmd="$*"
  mount -o bind /dev "$DEST/dev"
  chroot "$DEST" mount -t proc proc /proc || true
  chroot "$DEST" mount -t sysfs sys /sys || true
  chroot "$DEST" mount -t tmpfs none /tmp || true
  chroot "$DEST" "$cmd"
  chroot "$DEST" umount /tmp || true
  chroot "$DEST" umount /sys || true
  chroot "$DEST" umount /proc || true
  umount "$DEST/dev" || true
}

set -ex

function download_repo() {
  if [ ! -d "build/$1" ]; then
    git clone --depth=1 "$2" -b "$3" "build/$1"
  else
    (
      cd "build/$1" || exit 1
      git checkout .
      git reset --hard
      git clean -fd
      git pull
    )
  fi
}

function download_sources() {
  download_repo "sdm845-linux" "https://gitlab.com/sdm845-mainline/sdm845-linux.git/" "beryllium-dev-battery" &
  download_repo "firmware-xiaomi-beryllium" "https://gitlab.com/sdm845-mainline/firmware-xiaomi-beryllium.git/" "master" &
  download_repo "pmaports" "https://gitlab.com/postmarketOS/pmaports.git/" "master" &
  download_repo "efidroid-build" "https://github.com/efidroid/build.git" "master" &

  if [ ! -f "$TARBALL" ]; then
    wget "$ROOTFS" -O "$TARBALL" &
  fi

  wait
}

function setup_clean_rootfs() {
  rm -f "$ROOTFSIMG"
  fallocate -l "${IMAGE_SIZE}"M "$ROOTFSIMG"
  cat <<EOF | fdisk "$ROOTFSIMG"
o
n
p



t
83
a
w
EOF

  losetup -P "$LOOP_DEVICE" "$ROOTFSIMG"
  mkfs.f2fs -l ALARM "${LOOP_DEVICE}"p1
  mount "${LOOP_DEVICE}"p1 "$DEST"
}

function setup_dirty_rootfs() {
  if [ ! -f "$ROOTFSIMG" ]; then
    echo "You need to already have built a rootfs to use it"
    echo "Run build_phosh.sh or build_plasma_mobile.sh first"
    exit 1
  fi
  losetup -P "$LOOP_DEVICE" "$ROOTFSIMG"
  mount "${LOOP_DEVICE}"p1 "$DEST"
}

function build_rootfs() {
  tar --use-compress-program=pigz --same-owner -xpf "$TARBALL" -C "$DEST"

  rm -rf "$DEST/etc/resolv.conf"

  cp overlay/* "$DEST" -r

  if [ -n "$LOCAL_MIRROR" ]; then
    cp "$DEST/etc/pacman.conf" "$DEST/etc/pacman.conf.bak"
    cp "$DEST/etc/pacman.d/mirrorlist" "$DEST/etc/pacman.d/mirrorlist.bak"
    sed -i "s/Server = .*/Include = \/etc\/pacman\.d\/mirrorlist/" "$DEST/etc/pacman.conf"
    printf "Server = %s" "$LOCAL_MIRROR" >"$DEST/etc/pacman.d/mirrorlist"
  fi

  cat >"$DEST/install" <<EOF
#!/bin/bash
set -ex

$PRE_SCRIPT

pacman -Syy
pacman -Rdd --noconfirm linux-aarch64 linux-firmware # We supply our own kernel (trough boot.img) and firmware
pacman -Su --noconfirm --overwrite=*
yes | pacman -Scc
pacman -S --noconfirm --needed --overwrite=* \
  f2fs-tools \
  bluez \
  bluez-libs \
  bluez-utils \
  alsa-utils \
  wireless-regdb \
  danctnix-usb-tethering \
  danctnix-tweaks \
  alsa-ucm-beryllium \
  qrtr-git \
  tqftpserv-git \
  rmtfs-git \
  pd-mapper-git \
  iw \
  networkmanager \
  wpa_supplicant \
  sudo \
  xdg-user-dirs \
  mesa-git \
  $(printf " %s" "${EXTRA_PACKAGES[@]}")
yes | pacman -Scc

usermod -a -G network,video,audio,optical,storage,input,scanner,games,lp,rfkill,wheel alarm
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "alarm:123456" | chpasswd

sed -i 's|^#en_US.UTF-8|en_US.UTF-8|' /etc/locale.gen
cd /usr/share/i18n/charmaps
gzip -d UTF-8.gz
locale-gen
gzip UTF-8
echo "LANG=en_US.UTF-8" > /etc/locale.conf

systemctl enable sshd
systemctl enable usb-tethering
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable qrtr-ns
systemctl enable tqftpserv
systemctl enable rmtfs
systemctl enable pd-mapper

$POST_SCRIPT

pacman -Q | cut -f 1 -d " " | sed "s/-git$//" > /packages
EOF
  chmod +x "$DEST/install"
  do_chroot /install
  rm "$DEST/install"

  mv "$DEST/packages" "build/$IMAGE_NAME-packages.txt"

  cp build/firmware-xiaomi-beryllium/lib/firmware "$DEST/usr/lib" -r
}

function build_kernel() {
  cd build/sdm845-linux || exit 1

  # Reset kernel config
  git checkout .
  git reset --hard
  git clean -fd

  # Patch kernel config
  cat >>arch/arm64/configs/beryllium_defconfig <<EOF

CONFIG_DRM_FBDEV_EMULATION=y
CONFIG_CMDLINE_FORCE=n

CONFIG_MEDIA_SUPPORT=y
CONFIG_MEDIA_SUPPORT_FILTER=y
CONFIG_MEDIA_PLATFORM_SUPPORT=y
CONFIG_MEDIA_USB_SUPPORT=y
CONFIG_MEDIA_CONTROLLER=y

CONFIG_EXTCON=y
CONFIG_EXTCON_USB_GPIO=y
CONFIG_TYPEC_TCPCI=y
CONFIG_TYPEC_UCSI=y
CONFIG_TYPEC_QCOM_PMIC=y
CONFIG_USB_DWC2=y
CONFIG_USB_DWC3_OF_SIMPLE=y
CONFIG_USB_DWC3_DUAL_ROLE=y
CONFIG_USB_ANNOUNCE_NEW_DEVICES=y
CONFIG_USB_STORAGE=y
CONFIG_USB_HID=y
CONFIG_USB_PHY=y
CONFIG_USB_ULPI_BUS=y
CONFIG_USB_ROLE_SWITCH=y

CONFIG_ATH10K_SPECTRAL=y
CONFIG_ATH10K_DFS_CERTIFIED=y

CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_IOMMU=y
CONFIG_VIRTIO_INPUT=y
CONFIG_DRM_VIRTIO_GPU=y

CONFIG_BOOTSPLASH=y
CONFIG_LOGO=n

CONFIG_HIBERNATE_CALLBACKS=y
CONFIG_HIBERNATION=y
CONFIG_HIBERNATION_SNAPSHOT_DEV=y
CONFIG_PM_AUTOSLEEP=y
CONFIG_PM_WAKELOCKS_LIMIT=100
CONFIG_PM_WAKELOCKS_GC=y
CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y
CONFIG_ARCH_HIBERNATION_HEADER=y

CONFIG_CPU_FREQ_STAT=y
CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y
CONFIG_CPU_FREQ_GOV_PERFORMANCE=y
CONFIG_CPU_FREQ_GOV_POWERSAVE=y
CONFIG_CPU_FREQ_GOV_USERSPACE=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y
CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y
CONFIG_CPU_FREQ_GOV_CONSERVATIVE=y
CONFIG_ARM_QCOM_CPUFREQ_HW=y

CONFIG_ZRAM=y
CONFIG_ZRAM_WRITEBACK=y
CONFIG_ZRAM_MEMORY_TRACKING=y
CONFIG_ZSWAP=y
CONFIG_ZPOOL=y
CONFIG_ZBUD=y
CONFIG_Z3FOLD=y
CONFIG_ZSMALLOC=y
EOF

  # Apply bootsplash patches
  patch -Np1 <"../../bootsplash.patch"

  # Build kernel
  export ARCH=arm64
  export CROSS_COMPILE=aarch64-linux-gnu-
  MAKEFLAGS="-j$(nproc --all)" make beryllium_defconfig Image.gz modules dtbs
  cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium.dtb >arch/arm64/boot/.Image.gz-dtb

  # Install kernel into rootfs
  mkdir -p "$DEST/boot" "$DEST/usr/lib/modules"
  export INSTALL_PATH="$DEST/boot"
  export INSTALL_MOD_PATH="$DEST/usr"
  make zinstall modules_install
  cd ../..
}

function build_initramfs() {
  export KERNEL_RELEASE=$(cat build/sdm845-linux/include/config/kernel.release)

  cat >"$DEST/initramfs" <<EOF
#!/bin/bash
set -ex
mkinitcpio --generate /boot/$KERNEL_RELEASE-initramfs.img --kernel $KERNEL_RELEASE
EOF
  chmod +x "$DEST/initramfs"
  do_chroot /initramfs
  rm "$DEST/initramfs"

  mv "$DEST/boot/$KERNEL_RELEASE-initramfs.img" "build/$IMAGE_NAME-initramfs.img"
}

function build_bootimg() {
  FILE=build/pmaports/device/testing/device-xiaomi-beryllium/deviceinfo
  python3 build/efidroid-build/tools/mkbootimg \
    --kernel build/sdm845-linux/arch/arm64/boot/.Image.gz-dtb \
    --ramdisk "build/$IMAGE_NAME-initramfs.img" \
    --base "$(grep "offset_base" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --second_offset "$(grep "offset_second" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --kernel_offset "$(grep "offset_kernel" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --ramdisk_offset "$(grep "offset_ramdisk" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --tags_offset "$(grep "offset_tags" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --pagesize "$(grep "pagesize" <$FILE | sed "s/.*=\"//" | sed "s/\"//")" \
    --cmdline "root=LABEL=ALARM rw bootsplash.bootfile=bootsplash" \
    -o "build/$IMAGE_NAME-boot.img"
}

if [ -n "$ONLY_BOOTIMG" ]; then
  setup_dirty_rootfs
  build_kernel
else
  download_sources
  setup_clean_rootfs
  build_rootfs &
  build_kernel &
  wait
fi

build_initramfs
build_bootimg
cleanup

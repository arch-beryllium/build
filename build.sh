#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: build.sh <target>"
  echo "Targets: barebone, phosh, phosh-apps, phosh-bootimg, plasma-mobile, plasma-mobile-apps, plasma-mobile-bootimg, lomiri, lomiri-apps, lomiri-bootimg"
  exit 1
fi

if [ "$1" = "barebone" ]; then
  IMAGE_NAME="barebone"
  IMAGE_SIZE=$((1024 * 3))

elif [ "$1" = "barebone-bootimg" ]; then
  IMAGE_NAME="barebone"
  ONLY_BOOTIMG=1

elif [ "$1" = "phosh" ]; then
  IMAGE_NAME="phosh"
  IMAGE_SIZE=$((1024 * 4))

elif [ "$1" = "phosh-apps" ]; then
  IMAGE_NAME="phosh"
  INCLUDE_APPS=1
  IMAGE_SIZE=$((1024 * 4))

elif [ "$1" = "phosh-bootimg" ]; then
  IMAGE_NAME="phosh"
  ONLY_BOOTIMG=1

elif [ "$1" = "plasma-mobile" ]; then
  IMAGE_NAME="plasma-mobile"
  IMAGE_SIZE=$((1024 * 5))

elif [ "$1" = "plasma-mobile-apps" ]; then
  IMAGE_NAME="plasma-mobile"
  INCLUDE_APPS=1
  IMAGE_SIZE=$((1024 * 5))

elif [ "$1" = "plasma-mobile-bootimg" ]; then
  IMAGE_NAME="plasma-mobile"
  ONLY_BOOTIMG=1

elif [ "$1" = "lomiri" ]; then
  IMAGE_NAME="lomiri"
  IMAGE_SIZE=$((1024 * 6))

elif [ "$1" = "lomiri-apps" ]; then
  IMAGE_NAME="lomiri"
  INCLUDE_APPS=1
  IMAGE_SIZE=$((1024 * 6))

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

pacman -Syy
pacman -Rdd --noconfirm linux-aarch64 linux-firmware # Don't upgrade kernel and firmware which we will remove later anyway
pacman -Su --noconfirm --overwrite=*
pacman -S --noconfirm --needed --overwrite=* \
  f2fs-tools \
  bluez \
  bluez-libs \
  bluez-utils \
  alsa-utils \
  wireless-regdb \
  usb-tethering \
  alsa-ucm-beryllium \
  qrtr-git \
  tqftpserv-git \
  rmtfs-git \
  pd-mapper-git \
  iw \
  networkmanager \
  wpa_supplicant \
  sudo \
  xdg-user-dirs
if [ ${#EXTRA_INSTALL_PACKAGES[@]} -ne 0 ]; then
  pacman -S --noconfirm --needed --overwrite=* $(printf " %s" "${EXTRA_INSTALL_PACKAGES[@]}")
fi
if [ ${#EXTRA_UNINSTALL_PACKAGES[@]} -ne 0 ]; then
  pacman -Rdd --noconfirm $(printf " %s" "${EXTRA_UNINSTALL_PACKAGES[@]}")
fi
if [ "$IMAGE_NAME" != "barebone" ]; then
  sed -i 's/fsck)/fsck bootsplash)/' /etc/mkinitcpio.conf
fi
pacman -S --noconfirm --needed --overwrite=* \
  firmware-xiaomi-beryllium \
  linux-beryllium \
  linux-beryllium-headers

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
systemctl enable first_time_setup
systemctl enable mount_modem_firmware

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

if [ -n "$ONLY_BOOTIMG" ]; then
  setup_dirty_rootfs
  rebuild_kernel_ramdisk_bootimg
else
  download_sources
  setup_clean_rootfs
  build_rootfs
fi

extract_kernel_ramdisk_bootimg

cleanup

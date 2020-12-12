#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: build.sh <target>"
  echo "Targets: phosh, plasma-mobile, phosh-bootimg, plasma-mobile-bootimg"
  exit 1
fi

if [ "$1" = "phosh" ]; then
  export IMAGE_NAME="phosh"
elif [ "$1" = "plasma-mobile" ]; then
  export IMAGE_NAME="plasma-mobile"
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

if [ "$IMAGE_NAME" = "phosh" ]; then
  export IMAGE_SIZE=5120
  export EXTRA_PACKAGES=()
  EXTRA_PACKAGES+=("danctnix-phosh-ui-meta")
  EXTRA_PACKAGES+=("dialog")
  EXTRA_PACKAGES+=("evince-mobile")
  EXTRA_PACKAGES+=("firefox")
  EXTRA_PACKAGES+=("geary-mobile")
  EXTRA_PACKAGES+=("gedit")
  EXTRA_PACKAGES+=("gnome-calculator")
  EXTRA_PACKAGES+=("gnome-clocks")
  EXTRA_PACKAGES+=("gnome-maps")
  EXTRA_PACKAGES+=("gnome-usage-mobile")
  EXTRA_PACKAGES+=("gst-plugins-good")
  EXTRA_PACKAGES+=("gtherm")
  EXTRA_PACKAGES+=("lollypop")
  EXTRA_PACKAGES+=("megapixels")
  EXTRA_PACKAGES+=("mesa-git")
  EXTRA_PACKAGES+=("mobile-config-firefox")
  EXTRA_PACKAGES+=("mpg123")
  EXTRA_PACKAGES+=("noto-fonts-emoji")
  EXTRA_PACKAGES+=("purple-matrix")
  EXTRA_PACKAGES+=("purple-telegram")
  EXTRA_PACKAGES+=("pv")
  EXTRA_PACKAGES+=("twolame")
  EXTRA_PACKAGES+=("wavpack")
  export POST_SCRIPT=$(
    cat <<EOF
printf "[device]\nwifi.scan-rand-mac-address=no" > /etc/NetworkManager/conf.d/disable-random-mac.conf
printf "[Settings]\ngtk-application-prefer-dark-theme=1" > /etc/gtk-3.0/settings.ini
systemctl enable phosh
EOF
  )
fi
if [ "$IMAGE_NAME" = "plasma-mobile" ]; then
  export IMAGE_SIZE=5120
  export EXTRA_PACKAGES=()
  EXTRA_PACKAGES+=("accounts-qml-module")
  EXTRA_PACKAGES+=("adwaita-icon-theme")
  EXTRA_PACKAGES+=("bluedevil-git")
  EXTRA_PACKAGES+=("bluez-qt-git")
  EXTRA_PACKAGES+=("buho-git")
  EXTRA_PACKAGES+=("calindori-git")
  EXTRA_PACKAGES+=("desktop-file-utils")
  EXTRA_PACKAGES+=("discover-git")
  EXTRA_PACKAGES+=("enchant")
  EXTRA_PACKAGES+=("firefox")
  EXTRA_PACKAGES+=("flashlight")
  EXTRA_PACKAGES+=("flatpak")
  EXTRA_PACKAGES+=("git")
  EXTRA_PACKAGES+=("groff")
  EXTRA_PACKAGES+=("hdparm")
  EXTRA_PACKAGES+=("iio-sensor-proxy")
  EXTRA_PACKAGES+=("index-git")
  EXTRA_PACKAGES+=("kaccounts-integration-git")
  EXTRA_PACKAGES+=("kaccounts-providers-git")
  EXTRA_PACKAGES+=("kalk-git")
  EXTRA_PACKAGES+=("kcalendarcore-git")
  EXTRA_PACKAGES+=("kclock-git")
  EXTRA_PACKAGES+=("kcontacts-git")
  EXTRA_PACKAGES+=("keysmith-git")
  EXTRA_PACKAGES+=("kio-extras-git")
  EXTRA_PACKAGES+=("kongress-git")
  EXTRA_PACKAGES+=("kpeoplesink-git")
  EXTRA_PACKAGES+=("kpeoplevcard-git")
  EXTRA_PACKAGES+=("kplotting-git")
  EXTRA_PACKAGES+=("kquicksyntaxhighlighter-git")
  EXTRA_PACKAGES+=("krecorder-git")
  EXTRA_PACKAGES+=("kscreen-git")
  EXTRA_PACKAGES+=("kwallet-pam-git")
  EXTRA_PACKAGES+=("kweather-git")
  EXTRA_PACKAGES+=("libofono-qt")
  EXTRA_PACKAGES+=("lsb-release")
  EXTRA_PACKAGES+=("maliit-framework-git")
  EXTRA_PACKAGES+=("maliit-keyboard-git")
  EXTRA_PACKAGES+=("man-db")
  EXTRA_PACKAGES+=("man-pages")
  EXTRA_PACKAGES+=("megapixels")
  EXTRA_PACKAGES+=("mobile-config-firefox")
  EXTRA_PACKAGES+=("modemmanager-qt-git")
  EXTRA_PACKAGES+=("mplus-font")
  EXTRA_PACKAGES+=("ncdu")
  EXTRA_PACKAGES+=("networkmanager-qt-git")
  EXTRA_PACKAGES+=("nota-git")
  EXTRA_PACKAGES+=("noto-fonts-emoji")
  EXTRA_PACKAGES+=("ntfs-3g")
  EXTRA_PACKAGES+=("ofonoctl")
  EXTRA_PACKAGES+=("okular-mobile-git")
  EXTRA_PACKAGES+=("packagekit")
  EXTRA_PACKAGES+=("packagekit-qt5")
  EXTRA_PACKAGES+=("plasma-angelfish-git")
  EXTRA_PACKAGES+=("plasma-dialer-git")
  EXTRA_PACKAGES+=("plasma-mobile-nm-git")
  EXTRA_PACKAGES+=("plasma-mobile-settings")
  EXTRA_PACKAGES+=("plasma-nano-git")
  EXTRA_PACKAGES+=("plasma-pa-git")
  EXTRA_PACKAGES+=("plasma-phone-components-git")
  EXTRA_PACKAGES+=("plasma-phonebook-git")
  EXTRA_PACKAGES+=("plasma-pix-git")
  EXTRA_PACKAGES+=("plasma-settings-git")
  EXTRA_PACKAGES+=("plasma-wayland-protocols-git")
  EXTRA_PACKAGES+=("polkit-kde-agent-git")
  EXTRA_PACKAGES+=("powerdevil-git")
  EXTRA_PACKAGES+=("presage-git")
  EXTRA_PACKAGES+=("psensor")
  EXTRA_PACKAGES+=("pulseaudio")
  EXTRA_PACKAGES+=("pulseaudio-bluetooth")
  EXTRA_PACKAGES+=("qmlkonsole-git")
  EXTRA_PACKAGES+=("qmltermwidget")
  EXTRA_PACKAGES+=("qt5-base")
  EXTRA_PACKAGES+=("qt5-charts")
  EXTRA_PACKAGES+=("qt5-declarative")
  #EXTRA_PACKAGES+=("qt5-es2-base")
  #EXTRA_PACKAGES+=("qt5-es2-declarative")
  #EXTRA_PACKAGES+=("qt5-es2-multimedia")
  #EXTRA_PACKAGES+=("qt5-es2-wayland")
  EXTRA_PACKAGES+=("qt5-feedback")
  EXTRA_PACKAGES+=("qt5-graphicaleffects")
  EXTRA_PACKAGES+=("qt5-imageformats")
  EXTRA_PACKAGES+=("qt5-multimedia")
  EXTRA_PACKAGES+=("qt5-pim-git")
  EXTRA_PACKAGES+=("qt5-quickcontrols")
  EXTRA_PACKAGES+=("qt5-quickcontrols2")
  EXTRA_PACKAGES+=("qt5-script")
  EXTRA_PACKAGES+=("qt5-sensors")
  EXTRA_PACKAGES+=("qt5-tools")
  EXTRA_PACKAGES+=("qt5-translations")
  EXTRA_PACKAGES+=("qt5-virtualkeyboard")
  EXTRA_PACKAGES+=("qt5-wayland")
  EXTRA_PACKAGES+=("qt5-websockets")
  EXTRA_PACKAGES+=("qt5-webview")
  EXTRA_PACKAGES+=("sddm")
  EXTRA_PACKAGES+=("signon-kwallet-extension-git")
  EXTRA_PACKAGES+=("signon-plugin-oauth2")
  EXTRA_PACKAGES+=("signon-ui")
  EXTRA_PACKAGES+=("signond")
  EXTRA_PACKAGES+=("spacebar-git")
  EXTRA_PACKAGES+=("telegram-desktop")
  EXTRA_PACKAGES+=("telepathy-mission-control")
  EXTRA_PACKAGES+=("telepathy-ofono")
  EXTRA_PACKAGES+=("tlp")
  EXTRA_PACKAGES+=("usbutils")
  EXTRA_PACKAGES+=("vim")
  EXTRA_PACKAGES+=("vte3")
  EXTRA_PACKAGES+=("vvave-git")
  EXTRA_PACKAGES+=("wget")
  EXTRA_PACKAGES+=("xdg-desktop-portal-kde")
  export PRE_SCRIPT=$(
    cat <<EOF
  sed -i "s/#\[plasma-mobile\]/\[plasma-mobile\]/" /etc/pacman.conf
  sed -i "s/#Server = https:\/\/repo.lohl1kohl.de\/plasma-mobile\/aarch64\//Server = https:\/\/repo.lohl1kohl.de\/plasma-mobile\/aarch64\//" /etc/pacman.conf
  sed -i "s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" /etc/pacman.conf
EOF
  )
  export POST_SCRIPT=$(
    cat <<EOF
sed -i "s/kde/alarm/" /etc/sddm.conf
sed -i "s/EnableHiDPI=false/EnableHiDPI=true/g" /etc/sddm.conf
systemctl enable sddm

cp -r /etc/skel/.config /home/alarm/
cp /etc/xdg/applications-blacklistrc /home/alarm/.config/
cp /etc/xdg/kdeglobals /home/alarm/.config/
cp /etc/xdg/kwinrc /home/alarm/.config/
chown alarm:alarm /home/alarm/.config/ -R
EOF
  )
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

export ROOTFS="https://mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
export TARBALL="build/$(basename $ROOTFS)"
export DEST=$(mktemp -d)
export LOOP_DEVICE=$(losetup -f)
export ROOTFSIMG="build/rootfs-$IMAGE_NAME.img"

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

  umount -lc "$DEST" || true
  rm -rf "$DEST" || true

  losetup -d "$LOOP_DEVICE" || true
}
trap cleanup EXIT

do_chroot() {
  cmd="$*"
  mount -o bind /dev "$DEST/dev"
  chroot "$DEST" mount -t proc proc /proc || true
  chroot "$DEST" mount -t sysfs sys /sys || true
  chroot "$DEST" mount -t tmpfs none /tmp || true
  chroot "$DEST" "$cmd"
  chroot "$DEST" umount /tmp
  chroot "$DEST" umount /sys
  chroot "$DEST" umount /proc
  umount "$DEST/dev"
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
pacman -S --noconfirm --needed --overwrite=* \
  f2fs-tools \
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
systemctl enable ModemManager
systemctl enable bluetooth
systemctl enable qrtr-ns
systemctl enable tqftpserv
systemctl enable rmtfs
systemctl enable pd-mapper

$POST_SCRIPT

pacman -Q | cut -f 1 -d " " > /packages
EOF
  chmod +x "$DEST/install"
  do_chroot /install
  rm "$DEST/install"

  mv "$DEST/packages" "build/packages-$IMAGE_NAME"

  cp build/firmware-xiaomi-beryllium/lib/firmware "$DEST/usr/lib" -r
}

function build_kernel() {
  cd build/sdm845-linux || exit 1

  # Reset kernel config
  git checkout .

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
EOF

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
    --cmdline "root=LABEL=ALARM rw" \
    -o build/boot.img
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

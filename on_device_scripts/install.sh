#!/bin/bash
set -ex
pacman -Sy
pacman -Rdd --noconfirm linux-pine64
pacman -Rns --noconfirm device-pine64-pinephone uboot-pinephone rtl8723bt-firmware ov5640-firmware danctnix-eg25-misc anx7688-firmware
pacman -Su --noconfirm --overwrite=*
pacman -S --noconfirm --needed --overwrite=* fakeroot binutils git make gcc linux-aarch64-headers bluez-utils wireless-regdb danctnix-usb-tethering

ln -sf /usr/bin/gcc /usr/bin/aarch64-linux-gnu-gcc
cd /home/alarm
function build_package() {
  url=$1
  dir=$(basename "$url" | sed "s/\.git//")
  su alarm -s /bin/bash -c "git clone --depth=1 $url && cd $dir && MAKEFLAGS=-j$(nproc --all) makepkg"
}
function install_package() {
  pacman -U /home/alarm/"$1"/*.pkg* --noconfirm
}
function build_and_install_package() {
  build_package "$1"
  install_package "$(basename "$url" | sed "s/\.git//")"
}
build_and_install_package "https://github.com/jld3103/alsa-ucm-beryllium.git" &
build_and_install_package "https://aur.archlinux.org/qrtr-git.git"
for url in \
  "https://aur.archlinux.org/tqftpserv-git.git" \
  "https://aur.archlinux.org/rmtfs-git.git" \
  "https://aur.archlinux.org/pd-mapper-git.git"; do
  build_package "$url" &
done
wait
for package in \
  "tqftpserv-git" \
  "rmtfs-git" \
  "pd-mapper-git"; do
  install_package "$package"
done

systemctl enable sshd
systemctl enable usb-tethering
systemctl enable qrtr-ns
systemctl enable tqftpserv
systemctl enable rmtfs
systemctl enable pd-mapper

yes | pacman -Scc

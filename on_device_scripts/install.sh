#!/bin/bash
set -ex
pacman -Sy
pacman -Rdd --noconfirm linux-pine64
pacman -Rns --noconfirm device-pine64-pinephone uboot-pinephone rtl8723bt-firmware ov5640-firmware danctnix-eg25-misc anx7688-firmware
pacman -Su --noconfirm --overwrite=*
pacman -S --noconfirm --needed --overwrite=* bluez-utils alsa-utils wireless-regdb danctnix-usb-tethering alsa-ucm-beryllium qrtr-git tqftpserv-git rmtfs-git pd-mapper-git
yes | pacman -Scc

systemctl enable sshd
systemctl enable usb-tethering
systemctl enable qrtr-ns
systemctl enable tqftpserv
systemctl enable rmtfs
systemctl enable pd-mapper

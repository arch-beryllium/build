#!/bin/bash
set -ex
pacman-key --init
pacman-key --populate archlinuxarm
killall -KILL gpg-agent
pacman -Sy
pacman -Rdd --noconfirm linux-aarch64
pacman -Su --noconfirm --overwrite=*
pacman -S --noconfirm --needed --overwrite=* mkinitcpio fakeroot binutils git dhcp sudo bluez bluez-utils bluez-libs wireless-regdb
pacman -S --noconfirm --needed --overwrite=* curl xz iw rfkill netctl dialog wpa_supplicant pv networkmanager bootsplash-theme-danctnix v4l-utils
pacman -S --noconfirm --needed --overwrite=* danctnix-phosh-ui-meta flashlight xdg-user-dirs noto-fonts-emoji
pacman -S --noconfirm --needed --overwrite=* gedit evince-mobile mobile-config-firefox gnome-calculator gnome-clocks gnome-maps gnome-usage-mobile gtherm geary-mobile purple-matrix purple-telegram

usermod -a -G network,video,audio,optical,storage,input,scanner,games,lp,rfkill,wheel alarm

ln -sf /usr/bin/gcc /usr/bin/aarch64-linux-gnu-gcc
su alarm -s /bin/bash -c "cd /home/alarm && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg"
pacman -U /home/alarm/yay-bin/*.pkg* --noconfirm
rm /home/alarm/yay-bin -rf
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
su alarm -s /bin/bash -c "yay -S qrtr-git --noconfirm"
su alarm -s /bin/bash -c "yay -S tqftpserv-git rmtfs-git pd-mapper-git --noconfirm"
sed -i "s/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers

systemctl disable systemd-networkd
systemctl disable systemd-resolved
systemctl enable dhcpd4
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable phosh
systemctl enable qrtr-ns
systemctl enable tqftpserv
systemctl enable rmtfs
systemctl enable pd-mapper

sed -i 's|^#en_US.UTF-8|en_US.UTF-8|' /etc/locale.gen
cd /usr/share/i18n/charmaps
gzip -d UTF-8.gz
locale-gen
gzip UTF-8

yes | pacman -Scc

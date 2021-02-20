cat >"/usr/share/lightdm/lightdm.conf.d/50-lightdm-autologin.conf" <<EOF
[Seat:*]
autologin-user=alarm
autologin-user-timeout=0
EOF
groupadd -r autologin
gpasswd -a alarm autologin
systemctl enable lightdm

mkdir -p /etc/systemd/logind.conf.d
cat >"/etc/systemd/logind.conf.d/ignore-power-key.conf" <<EOF
[Login]
HandlePowerKey=ignore
EOF

cat >>"/etc/deviceinfo/alias.conf" <<EOF
Xiaomi Pocophone F1=beryllium
EOF
cat >"/etc/deviceinfo/beryllium.conf" <<EOF
[device]
Name=beryllium
PrettyName=Xiaomi Pocophone F1
DeviceType=phone
GridUnit=20
PrimaryOrientation=Portrait
EOF

cp -r /etc/skel/. /home/alarm/
cp -r /etc/xdg/. /home/alarm/.config/
rm /home/alarm/.config/systemd/user # Broken symlink that's not needed

chown alarm:alarm /home/alarm/ -R

mkdir -p /usr/lib/systemd/user/ayatana-indicators.target.wants
ln -sf /usr/lib/systemd/user/ayatana-indicator-datetime.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-datetime.service
ln -sf /usr/lib/systemd/user/ayatana-indicator-display.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-display.service
ln -sf /usr/lib/systemd/user/ayatana-indicator-messages.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-messages.service
ln -sf /usr/lib/systemd/user/ayatana-indicator-power.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-power.service
ln -sf /usr/lib/systemd/user/ayatana-indicator-session.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-session.service
ln -sf /usr/lib/systemd/user/ayatana-indicator-sound.service /usr/lib/systemd/user/ayatana-indicators.target.wants/ayatana-indicator-sound.service
ln -sf /usr/lib/systemd/user/indicator-network.service /usr/lib/systemd/user/ayatana-indicators.target.wants/indicator-network.service
ln -sf /usr/lib/systemd/user/indicator-transfer.service /usr/lib/systemd/user/ayatana-indicators.target.wants/indicator-transfer.service
ln -sf /usr/lib/systemd/user/indicator-bluetooth.service /usr/lib/systemd/user/ayatana-indicators.target.wants/indicator-bluetooth.service
ln -sf /usr/lib/systemd/user/indicator-location.service /usr/lib/systemd/user/ayatana-indicators.target.wants/indicator-location.service

systemctl enable ModemManager
systemctl enable tlp
systemctl enable zswap-arm
systemctl enable repowerd
systemctl enable hfd-service
systemctl enable sensorfwd

ln -sf /usr/share/backgrounds/archlinux/conference.png /usr/share/backgrounds/warty-final-ubuntu.png

mkdir -p /usr/lib/systemd/user/graphical-session.target.wants
ln -sf /usr/lib/systemd/user/maliit-server.service /usr/lib/systemd/user/graphical-session.target.wants/maliit-server.service

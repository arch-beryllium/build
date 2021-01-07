cat >/etc/NetworkManager/conf.d/disable-random-mac.conf <<EOF
[device]
wifi.scan-rand-mac-address=no
EOF
cat >/etc/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
EOF

systemctl enable ModemManager
systemctl enable phosh
systemctl enable zramswap

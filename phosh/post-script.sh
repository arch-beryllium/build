ln -sf /usr/lib/firmware/bootsplash-themes/danctnix/bootsplash /lib/firmware/bootsplash

cat >/etc/NetworkManager/conf.d/disable-random-mac.conf <<EOF
[device]
wifi.scan-rand-mac-address=no
EOF
cat >/etc/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
EOF
systemctl enable phosh

ln -sf /lib/firmware/bootsplash-themes/manjaro/bootsplash /lib/firmware/bootsplash

sed -i "s/kde/alarm/" /etc/sddm.conf
sed -i "s/EnableHiDPI=false/EnableHiDPI=true/g" /etc/sddm.conf
systemctl enable sddm

cp -r /etc/skel/. /home/alarm/
cp -r /etc/xdg/. /home/alarm/.config/

mkdir -p /home/alarm/.config/autostart-scripts
cat >>/home/alarm/.config/autostart-scripts/initial-scale.sh <<EOF
#!/bin/bash
sleep 5s
export QT_QPA_PLATFORM=wayland
kscreen-doctor output.1.scale.2.5
rm /home/alarm/.config/autostart-scripts/initial-scale.sh
EOF
chmod a+x /home/alarm/.config/autostart-scripts/initial-scale.sh

chown alarm:alarm /home/alarm/ -R

systemctl enable tlp
systemctl enable zswap-arm

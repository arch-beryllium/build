sed -i "s/kde/alarm/" /etc/sddm.conf
sed -i "s/EnableHiDPI=false/EnableHiDPI=true/g" /etc/sddm.conf
systemctl enable sddm

cp -r /etc/skel/. /home/alarm/
cp -r /etc/xdg/. /home/alarm/.config/
chown alarm:alarm /home/alarm/ -R

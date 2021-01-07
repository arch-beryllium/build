#!/bin/bash
sed -i 's/resizerootfs//g' /etc/mkinitcpio.conf
mkinitcpio -p linux-beryllium
update-bootimg

systemctl disable first_time_setup
rm /opt/first_time_setup.sh
rm /usr/lib/systemd/system/first_time_setup.service
rm /usr/lib/initcpio/hooks/resizerootfs
rm /usr/lib/initcpio/install/resizerootfs

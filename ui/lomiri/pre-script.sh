sed -i "s/#lomiri: //" /etc/pacman.conf
sed -i "s/#plasma-mobile: //" /etc/pacman.conf # For some reason they include some stuff from Plasma Mobile (mostly bluedevil I think)

ln -sf /usr/lib/firmware/bootsplash-themes/danctnix/bootsplash /lib/firmware/bootsplash

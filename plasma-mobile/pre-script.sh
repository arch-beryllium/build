sed -i "s/#\[plasma-mobile\]/\[plasma-mobile\]/" /etc/pacman.conf
sed -i "s/#Server = https:\/\/repo.lohl1kohl.de\/plasma-mobile\/aarch64\//Server = https:\/\/repo.lohl1kohl.de\/plasma-mobile\/aarch64\//" /etc/pacman.conf
sed -i "s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/" /etc/pacman.conf

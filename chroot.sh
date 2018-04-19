#Potential variables: timezone, lang and local

passwd

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

pacman --noconfirm --needed -S grub && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

pacman --noconfirm --needed -S dialog

dialog --title "Install dotfiles" --yesno "Do you want to install the dotfiles?" 15 60 && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install.sh && sh ./install.sh

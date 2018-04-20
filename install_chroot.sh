# Set the root password
passwd

# Set the timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Configure hostname

touch /etc/hostname
echo "tartarus" >> /etc/hostname

echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.1.1    tartarus.localdomain    tartarus" >> /etc/hosts

# Install boot
pacman --noconfirm --needed -S grub && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg
 sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/sda4:crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda4:crypt"/g' /etc/default/grub

# Install network manager
pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

# Install dialog for chroot
pacman --noconfirm --needed -S dialog

dialog --title "Install dotfiles" --yesno "Do you want to install the dotfiles?" 15 60 \
    && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_root.sh \
    && sh ./install_root.sh

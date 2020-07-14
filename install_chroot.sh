# Set the root password
passwd

# Set the timezone
timedatectl set-timezone Europe/Berlin

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Install dialog for chroot
pacman --noconfirm --needed -S dialog
dialog --infobox "Install grub for boot..." 4 40

# Install boot
pacman --noconfirm --needed -S grub && grub-install --target=i386-pc /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null

# For encrypted home
# sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/sda4:crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda4:crypt"/g' /etc/default/grub

# To boot with encrypted home
# echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab
# echo "/dev/mapper/home      /home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab

# TODO bring config user here and add same for root

dialog --title "Continue installation" --yesno "Do you want to install all the softwares and the dotfiles?" 15 60 \
    && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_root.sh \
    && sh ./install_root.sh

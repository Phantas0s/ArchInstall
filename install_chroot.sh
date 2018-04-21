# Set the root password
passwd

mkdir -m 700 /etc/luks-keys
dd if=/dev/random of=/etc/luks-keys/home bs=1 count=256

cryptsetup -d /etc/luks-keys/home open /dev/sda4 home

mkfs.ext4 /dev/mapper/home
mount /dev/mapper/home /home

echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab

genfstab -U /mnt >> /mnt/etc/fstab
echo "/dev/mapper/home      /home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab

# Set the timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

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

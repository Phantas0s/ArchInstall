# Set the root password
pass1=$(dialog --no-cancel --passwordbox "Enter your root password" 10 60 3>&1 1>&2 2>&3 3>&1)
pass2=$(dialog --no-cancel --passwordbox "Enter your root password again. To be sure..." 10 60 3>&1 1>&2 2>&3 3>&1)

while [ $pass1 != $pass2 ]
do
    pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter root password again." 10 60 3>&1 1>&2 2>&3 3>&1)
    pass2=$(dialog --no-cancel --passwordbox "Retype root password." 10 60 3>&1 1>&2 2>&3 3>&1)
    unset pass2
done
cat <<EOF | passwd
$pass1
$pass1
EOF

# Set the timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

dialog --infobox "Install grub for boot..." 4 40

# Install boot
pacman --noconfirm --needed -S grub && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg
 sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/sda4:crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda4:crypt"/g' /etc/default/grub

# To boot with encrypted home
echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab
echo "/dev/mapper/home      /home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab

# Install dialog for chroot
pacman --noconfirm --needed -S dialog

dialog --title "Continue installation" --yesno "Do you want to install all the softwares and the dotfiles?" 15 60 \
    && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_root.sh \
    && sh ./install_root.sh

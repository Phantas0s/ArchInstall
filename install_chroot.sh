# Set the root password
passwd

# Set the timezone
timedatectl set-timezone Europe/Berlin

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Install dialog for chroot
pacman --noconfirm --needed -S dialog
dialog --infobox "Install grub for boot..." 4 40

# Install GRUB
pacman --noconfirm --needed -S grub && grub-install --target=i386-pc /dev/sda
# Generate GRUM main config
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null

# For encrypted home
# sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/sda4:crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda4:crypt"/g' /etc/default/grub

# To boot with encrypted home
# echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab
# echo "/dev/mapper/home      /home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab

# TODO do same for root?
function config_user() {
    dialog --title "Add User" --msgbox "It's now time to create a user" 10 60

    name=$(dialog --no-cancel --inputbox "First, please enter your username" 10 60 --output-fd 1)
    pass1=$(dialog --no-cancel --passwordbox "Enter your password" 10 60 --output-fd 1)
    pass2=$(dialog --no-cancel --passwordbox "Enter your password again. To be sure..." 10 60 --output-fd 1)

    while [ $pass1 != $pass2 ]
    do
        pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter password again." 10 60 --output-fd 1)
        pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 --output-fd 1)
        unset pass2
    done

    dialog --infobox "Adding user $name..." 4 50
    useradd -m -g wheel -s /bin/bash $name >> $output
    echo "$name:$pass1" | chpasswd >> $output
}

config_user

dialog --title "Continue installation" --yesno "Do you want to install all the softwares and the dotfiles?" 15 60 \
    && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_root.sh \
    && sh ./install_root.sh

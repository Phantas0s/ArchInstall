#!/bin/bash

uefi=$(cat /var_uefi) && hd=$(cat /var_hd)

pacman --noconfirm --needed -S dialog
pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
    pacman -S --noconfirm efibootmgr
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
else
    grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Set the timezone
timedatectl set-timezone Europe/Berlin

# Set hardware clock from system clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

function config_user() {
    if [[ -z $1 ]]; then
        dialog --no-cancel --inputbox "Please enter your username" 10 60 2> name
    else
        echo "$1" > name
    fi

    dialog --no-cancel --passwordbox "Enter your password" 10 60 2> pass1
    dialog --no-cancel --passwordbox "Enter your password again. To be sure..." 10 60 2> pass2

    while [ "$(cat pass1)" != "$(cat pass2)" ]
    do
        dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter password again." 10 60 2> pass1
        dialog --no-cancel --passwordbox "Retype password." 10 60 2> pass2
    done
    name=$(cat name)
    pass1=$(cat pass1)

    rm name pass1 pass2

    # Create user if doesn't exist
    if [[ ! "$(id -u "$name" 2> /dev/null)" ]]; then
        dialog --infobox "Adding user $name..." 4 50
        useradd -m -g wheel -s /bin/bash "$name"
    fi

    # Add password to user
    echo "$name:$pass1" | chpasswd
}

dialog --title "root password" --msgbox "It's time to add a password for the root user" 10 60
config_user root

dialog --title "Add User" --msgbox "We can't always be root. Too many responsibilities. Let's create another user." 10 60
config_user

echo "$name" > /tmp/user_name

dialog --title "Continue installation" --yesno "Do you want to install all the softwares and the dotfiles?" 10 60 \
    && curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_apps.sh \
    && bash ./install_apps.sh

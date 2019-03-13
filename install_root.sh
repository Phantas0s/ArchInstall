#!/bin/bash

dialog --title "Welcome!" --msgbox "Welcome to Phantas0s dotfiles and software installation script for Arch linux.\n" 10 60

name=$(dialog --no-cancel --inputbox "First, please enter your username" 10 60 3>&1 1>&2 2>&3 3>&1)
pass1=$(dialog --no-cancel --passwordbox "Enter your password" 10 60 3>&1 1>&2 2>&3 3>&1)
pass2=$(dialog --no-cancel --passwordbox "Enter your password again. To be sure..." 10 60 3>&1 1>&2 2>&3 3>&1)

while [ $pass1 != $pass2 ]
do
    pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
    pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
    unset pass2
done

dialog --infobox "Adding user \"$name\"..." 4 50
useradd -m -g wheel -s /bin/bash $name >/dev/tty6
echo "$name:$pass1" | chpasswd >/dev/tty6

cmd=(dialog --separate-output --nocancel  --buildlist "Press <SPACE> to select the packages you want to install. This script will install all the packages you put in the right column.\n
Use \"^\" and \"\$\" to move to the left and right columns respectively. Press <ENTER> when done.\n\n You can see the description of each packages in the file progs.csv" 22 76 16)
options=(V "Vmware tools" off
         O "Owncloud client" off
         E "Essentials" on
         T "Recommended tools" on
         G "Git & git tools" on
         I "i3 Tile manager & Desktop" on
         M "Tmux" on
         N "Neovim" on
         K "Keyring applications" on
         U "Urxvt unicode" on
         Z "Unix Z-Shell (zsh)" on
         S "Ripgrep" on
         C "Compton" on
         B "Browsers (firefox + chromium)" on
         R "Ranger terminal file manager" on
         P "Programming environment (PHP, Ruby, Go, Docker)" on
         X "KeepassX" on
         J "Jrnl" on
         Y "Mysql (mariadb) & mysql tools" on
         H "Hugo static site generator" off
         F "Freemind - mind mapping software" off
         D "Thunderbird" off
         A "Anki" off
         Q "Gcolor" off
         L "TranslateShell" off
     )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

let="\(\|[a-z]\|$(echo $choices | sed -e "s/ /\\\|/g")\)"

dialog --title "Let's get this party started!" --msgbox \
"The rest of the installation will now be almost automated, so you can sit back and relax.\n\n
Some questions will be asked while installing the dotfiles at the end of the installation.\n\n

It will take some time, but when done your system will be fully functional.\n\n
Now just press <OK> and the system will begin the installation!" 13 60 \
|| (clear && exit)

clear

dialog --infobox "Refreshing Arch Keyring..." 4 40
pacman --noconfirm -Sy archlinux-keyring >/dev/tty6

dialog --infobox "Updating the system..." 4 40
pacman -Syu --noconfirm >/dev/tty6

dialog --infobox "Getting program list..." 4 40
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/progs.csv > /tmp/progs.csv

if [ -f /tmp/aur_queue ];
    then
        rm /tmp/aur_queue &>/dev/tty6
fi

count=$(cat /tmp/progs.csv | grep -G ",$let," | wc -l)
n=0
installProgram() {
    ( (pacman --noconfirm --needed -S $1 &>/dev/tty6 && echo $1 installed.) \
    || echo $1 >> /tmp/aur_queue) \
    || echo $1 >> /tmp/arch_install_failed ;
}

for x in $(cat /tmp/progs.csv | grep -G ",$let," | awk -F, {'print $1'})
do
    n=$((n+1))
    dialog --title "Arch Linux Installation" --infobox \
    "Downloading and installing program $n out of $count: $x...\n\n.
    You can watch the output on tty6 (ctrl + alt + F6)." 8 70

    installProgram $x >/dev/tty6

    # Needed if system installed in VMWare
    if [ $x = "open-vm-tools" ];
    then
        systemctl enable vmtoolsd.service
        systemctl enable vmware-vmblock-fuse.service
    fi

    if [ $x = "zsh" ];
    then
        # zsh as default terminal for user
        chsh -s $(which zsh) $name
    fi

    if [ $x = "docker" ];
    then
        groupadd docker
        gpasswd -a $name docker
        systemctl enable docker.service

        # Put Docker files on home partition / not sure if it's a good idea...
        # echo "{\n\
        #     /home/$name/docker\n\
        # }" > /etc/docker/daemon.json
    fi

    if [ $x = "at" ];
    then
        systemctl enable atd.service
    fi

    if [ $x = "mariadb" ];
    then
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    fi

done

dialog --infobox "Install composer..." 4 40
wget https://getcomposer.org/composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 775 /usr/local/bin/composer

# Create folder to mount usb keys
mkdir -p /mnt/usbkey/ >/dev/null

curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers_tmp > /etc/sudoers
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_user.sh > /tmp/install_user.sh;
sudo -u $name sh /tmp/install_user.sh
rm -f /tmp/install_user.sh

dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers > /etc/sudoers

dialog --infobox "Disable the famous BIP sound we all love" 10 50
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf


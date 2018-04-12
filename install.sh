#!/bin/bash
pacman -S --noconfirm --needed dialog \
|| (echo "Impossible to run the script. Please verify that: \n - You have Internet \n - You execute the script as root\n\n" && exit)

dialog --title "Welcome!" --msgbox "Welcome to Phantas0s installation script for Arch linux.\n" 10 60

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

cmd=(dialog --separate-output --nocancel  --buildlist "Press <SPACE> to select the packages you want to install. This script will install all the packages you put in the right column.
Use \"^\" and \"\$\" to move to the left and right columns respectively. Press <ENTER> when done." 22 76 16)
options=(V "Vmware tools" off
         E "Essentials" on
         T "Recommended tools" on
         G "Git & git tools" on
         I "i3 Tile manager & Desktop" on
         M "Tmux" on
         N "Neovim" on
         K "Keyring applications" on
         U "Urxvt unicode" on
         Z "Unix Z-Shell (ZSH)" on
         S "Search tool ripgrep" on
         C "Compton - manage transparency" on
         B "Browsers (firefox + chromium)" on
         R "Ranger terminal file manager" on
         P "Programming environment (PHP, Ruby, Go, Docker)" on
         X "KeepassX" on
         L "Nextcloud" on
         J "Jrnl" on
         Y "Mysql (mariadb) & mysql tools" on
     )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

let="\(\|[a-z]\|$(echo $choices | sed -e "s/ /\\\|/g")\)"

dialog --title "Let's get this party started!" --msgbox \
"The rest of the installation will now be totally automated, so you can sit back and relax.\n\n
It will take some time, but when done, you can relax even more with your complete system.\n\n
Now just press <OK> and the system will begin installation!" 13 60 \
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

    if [[ $x = "docker" ]];
    then
        dialog --infobox "Add user $name to docker group..." 4 40
        groupadd docker
        gpasswd -a $name docker
    fi
done

dialog --infobox "Install composer..." 4 40
wget https://getcomposer.org/composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 775 /usr/local/bin/composer

dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers > /etc/sudoers

curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_user.sh > /tmp/install_user.sh;
sudo -u $name bash /tmp/install_user.sh
rm -f /tmp/install_user.sh

dialog --infobox "[$(whoami)] Installing .dotfiles..." 10 60
cd /home/$(whoami)/.dotfiles
sudo -u $name source env >/dev/null
sudo -u $name bash install.sh -y
cd -

dialog --infobox "Enabling Network Manager..." 4 40
systemctl enable NetworkManager
systemctl start NetworkManager

dialog --infobox "Disable the famous BIP sound we all love" 10 50
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

dialog --title "All done!" \
--msgbox "Congrats! The install is done! \n\nTo run the new graphical environment, you need to restart your computer, log in and type \"startx\"" 12 80

dialog --title "Reboot time" \
--yesno "It is adviced to restart your computer. Do you want to restart now?" 7 60

response=$?
case $response in
   0) reboot;;
   1) clear;;
esac

#!/bin/bash

# Path to your CSV where every possible programs are listed
# TODO would be nicer to have another format (yml array style)
dialog --infobox "Disable the famous BIP sound we all love" 10 50
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

dialog --infobox "Get necessary files..." 4 40
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/progs.csv > /tmp/progs.csv
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_user.sh > /tmp/install_user.sh;
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers_tmp > /etc/sudoers

function config_user() {
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

    dialog --infobox "Adding user $name..." 4 50
    useradd -m -g wheel -s /bin/bash $name >/dev/tty6
    echo "$name:$pass1" | chpasswd >/dev/tty6
}

function install_progs() {
    choices=$(dialog --checklist --stdout "You can here choose the programs you want, according to your own CSV file:" 0 0 0  \
            essential "Essentials" on \
            compression "Compression Tools" on \
            tools "Very nice tools to have (highly recommended)" on \
            git "Git & git tools" on \
            i3 "i3 Tile manager & Desktop" on \
            tmux "Tmux" on \
            neovim "Neovim" on \
            keyring "Keyring applications" on \
            urxvt "Urxvt unicode" on \
            zsh "Unix Z-Shell (zsh)" on \
            ripgrep "Ripgrep" on \
            firefox "Firefox (browser)" on \
            min "Min (browser)" on \
            vifm "vifm (terminal file manager)" on \
            programming "Programming environments (PHP, Ruby, Go, Docker, Clojure)" on \
            keepass "KeepassX" on \
            notes "Note taking systems" on \
            sql "Mysql (mariadb) & mysql tools" on \
            thunderbird "Thunderbird" off \
            graphism "Design" off \
            office "Office tools (Libreoffice...)" \ off
            vmware "Vmware tools" off \
            language "Language tools" off \
            multimedia "Multimedia" off \
            nextcloud "Nextcloud client" off \
            network "Network Configuration" off \
            hugo "Hugo static site generator" off \
            freemind "Freemind - mind mapping software" off)

    dialog --title "Let's go!" --msgbox \
    "The system will now install everything you need\n\n
    It might take some time.\n\n " 13 60 \
    || (clear && exit)

    clear

    dialog --infobox "Refreshing Arch Keyring..." 4 40
    pacman --noconfirm -Sy archlinux-keyring >/dev/tty6

    dialog --infobox "Updating the system..." 4 40
    pacman -Syu --noconfirm >/dev/tty6


    if [ -f /tmp/aur_queue ];
        then
            rm /tmp/aur_queue &>/dev/tty6
    fi

    selection=$(echo $choices | sed -e "s/ /,|^/g")
    lines=$(cat "/tmp/progs.csv" | grep -E "$selection")
    count=$(echo $lines | wc -l)
    progs=$(echo $lines | awk -F, {'print $2'})

    echo $progs

    c=0
    echo $progs | while IFS= read -r line; do
        c=$(( $c + 1 ))

        dialog --title "Arch Linux Installation" --infobox \
        "Downloading and installing program $c out of $count: $line...\n\n.
        You can watch the output on tty6 (ctrl + alt + F6)." 8 70

        ( (pacman --noconfirm --needed -S $line &>/dev/tty6 && echo $1 installed!) \
        || echo $1 >> /tmp/aur_queue) \
        || echo $1 >> /tmp/arch_install_failed ;

        # Needed if system installed in VMWare
        if [ $x = "open-vm-tools" ]; then
            systemctl enable vmtoolsd.service
            systemctl enable vmware-vmblock-fuse.service
        fi

        if [ $x = "zsh" ]; then
            # zsh as default terminal for user
            chsh -s $(which zsh) $name
        fi

        if [ $x = "docker" ]; then
            groupadd docker
            gpasswd -a $name docker
            systemctl enable docker.service
        fi

        if [ $x = "at" ]; then
            systemctl enable atd.service
        fi

        if [ $x = "mariadb" ]; then
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
        fi
    done

    dialog --infobox "Install composer..." 4 40
    wget https://getcomposer.org/composer.phar \
        && mv composer.phar /usr/local/bin/composer \
        && chmod 775 /usr/local/bin/composer

}

function install_user() {
    dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40

    # Change user and begin the install use script
    sudo -u $name sh /tmp/install_user.sh
    rm -f /tmp/install_user.sh
}

# Run!
config_user
install_progs
install_user

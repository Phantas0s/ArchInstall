#!/bin/bash

name=$(cat user_name)

dry_run=${dry_run:-false}
output=${output:-/tmp/arch-install-logs}
progs_path=${progs_path:-/tmp/progs.csv}
while getopts d:o:p: option
do
    case "${option}"
        in
        d) dry_run=${OPTARG};;
        o) output=${OPTARG};;
        p) progs_path=${OPTARG};;
    esac
done

local progs_path="/tmp/progs.csv"

dialog --infobox "Get necessary files..." 4 40
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/progs.csv > $progs_path
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_user.sh > /tmp/install_user.sh;
    curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers_tmp > /etc/sudoers

function pacman_install() {
    ((pacman --noconfirm --needed -S $1 &> $output && echo $1 installed!) \
    || echo $1 >> /tmp/aur_queue) \
    || echo $1 >> /tmp/arch_install_failed ;
}

function fake_install() {
    echo "$1 fakely installed!" >> $output
}

function install_progs() {
    dialog --title "Welcome!" --msgbox "Welcome to Phantas0s dotfiles and software installation script for Arch linux.\n" 10 60

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
            sql "Mysql (mariadb) & mysql tools" on \
            jrnl "Simple CLI journal" on \
            joplin "Note taking system" off \
            thunderbird "Thunderbird" off \
            graphism "Design" off \
            pandoc "Pandoc and usefull dependencies" off \
            office "Office tools (Libreoffice...)" off \
            vmware "Vmware tools" off \
            language "Language tools" off \
            multimedia "Multimedia" off \
            nextcloud "Nextcloud client" off \
            network "Network Configuration" off \
            hugo "Hugo static site generator" off \
            freemind "Freemind - mind mapping software" off)

    dialog --title "Let's go!" --msgbox \
    "The system will now install everything you need.\n\n
    It will take some time.\n\n " 13 60 \
    || (clear && exit)

    clear

    if [ "$dry_run" = false ]; then
        dialog --infobox "Refreshing Arch Keyring..." 4 40
        pacman --noconfirm -Sy archlinux-keyring >> $output

        dialog --infobox "Updating the system..." 4 40
        pacman -Syu --noconfirm >> $output
    fi

    if [ -f /tmp/aur_queue ];
        then
            rm /tmp/aur_queue >> $output 2>&1
    fi

    selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
    lines=$(cat "$progs_path" | grep -E "$selection")
    count=$(echo "$lines" | wc -l)
    progs=$(echo "$lines" | awk -F, {'print $2'})

    if [ "$dry_run" = false ]; then
        echo "$selection" >> $output
        echo "$lines" >> $output
        echo "$count" >> $output
    fi

    c=0
    echo "$progs" | while IFS= read -r line; do
        c=$(( $c + 1 ))

        dialog --title "Arch Linux Installation" --infobox \
        "Downloading and installing program $c out of $count: $line...\n\n.
        You can watch the output on tty6 (ctrl + alt + F6)." 8 70

        if [ "$dry_run" = false ]; then
            pacman_install $line

            # Needed if system installed in VMWare
            if [ $line = "open-vm-tools" ]; then
                systemctl enable vmtoolsd.service
                systemctl enable vmware-vmblock-fuse.service
            fi

            if [ $line = "zsh" ]; then
                # zsh as default terminal for user
                chsh -s $(which zsh) $name
            fi

            if [ $line = "docker" ]; then
                groupadd docker
                gpasswd -a $name docker
                systemctl enable docker.service
            fi

            if [ $line = "at" ]; then
                systemctl enable atd.service
            fi

            if [ $line = "mariadb" ]; then
                mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            fi
        else
            fake_install $line
        fi
    done
}

function install_user() {
    dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40
    # Change user and begin the install use script
    if [ "$dry_run" = false ]; then
        sudo -u $name sh /tmp/install_user.sh
        rm -f /tmp/install_user.sh
    fi
}

# Path to your CSV where every possible programs are listed
# TODO would be nicer to have another format (yml array style)
dialog --infobox "Disable the famous BIP sound we all love" 10 50
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# Run!
config_user
install_progs
install_user

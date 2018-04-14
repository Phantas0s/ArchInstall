#!/bin/bash

#Install an AUR package manually.
aurinstall() {
    curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz \
    && tar -xvf $1.tar.gz \
    && cd $1 \
    && makepkg --noconfirm -si \
    && cd .. \
    && rm -rf $1 $1.tar.gz ;
}

#aurcheck runs on each of its arguments, if the argument is not already installed, it either uses packer to install it, or installs it manually.
aurcheck() {
    qm=$(pacman -Qm | awk '{print $1}')
    for arg in "$@"
    do
        if [[ $qm = *"$arg"* ]]; then
            echo $arg is already installed.
        else
            echo $arg not installed.
            packer --noconfirm -S $arg >/dev/null || aurinstall $arg
        fi
    done
}

dialog --infobox "[$(whoami)] Installing \"packer\", an AUR helper..." 10 60
aurcheck packer >/dev/null

count=$(cat /tmp/aur_queue | wc -l)
n=0

for prog in $(cat /tmp/aur_queue)
do
	n=$((n+1))
    dialog --infobox "[$(whoami)] AUR install - Downloading and installing program $n out of $count: $prog..." 10 60
	aurcheck $prog >/dev/null
done

if [ ! -d /home/$(whoami)/.dotfiles ];
    then
        dialog --infobox "[$(whoami)] Downloading .dotfiles..." 10 60
        git clone https://github.com/Phantas0s/.dotfiles.git /home/$(whoami)/.dotfiles >/dev/null
fi

dialog --infobox "[$(whoami)] Setting zsh has default terminal. \n Please enter your password" 10 60
command -v "zsh" >/dev/null && chsh -s $(which zsh)

dialog --infobox "[$(whoami)] Installing .dotfiles..." 10 60
cd /home/$(whoami)/.dotfiles && source ./env
(command -v "zsh" >/dev/null && zsh ./install.sh -y) || sh ./install.sh -y
cd -

dialog --infobox "[$(whoami)] Create base folders" 10 60

mkdir -p /home/$(whoami)/Documents/ >/dev/null
mkdir -p /home/$(whoami)/Downloads/ >/dev/null
mkdir -p /home/$(whoami)/Workspace/ >/dev/null
mkdir -p /home/$(whoami)/Softwares/ >/dev/null

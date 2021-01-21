#!/bin/bash

name=$(cat /tmp/user_name)

dry_run=${dry_run:-false}
output=${output:-/tmp/arch_install}
apps_path=${apps_path:-/tmp/apps.csv}
while getopts d:o:p: option
do
    case "${option}"
        in
        d) dry_run=${OPTARG};;
        o) output=${OPTARG};;
        p) apps_path=${OPTARG};;
    esac
done

apps_path="/tmp/apps.csv"
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/apps.csv > $apps_path

function pacman_install() {
    ((pacman --noconfirm --needed -S "$1" &>> "$output") || echo "$1" &>> /tmp/aur_queue);
}

function fake_install() {
    echo "$1 fakely installed!" >> "$output"
}

# Add multilib repo for steam
echo "[multilib]" >> /etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

dialog --title "Welcome!" --msgbox "Welcome to Phantas0s dotfiles and software installation script for Arch linux.\n" 10 60

apps=("essential" "Essentials" on
      "compression" "Compression Tools" on
      "tools" "Very nice tools to have (highly recommended)" on
      "audio" "Audio tools" on
      "git" "Git & git tools" on
      "i3" "i3 Tile manager & Desktop" on
      "tmux" "Tmux" on
      "neovim" "Neovim" on
      "keyring" "Keyring applications" on
      "urxvt" "Urxvt unicode" on
      "zsh" "Unix Z-Shell (zsh)" on
      "ripgrep" "Ripgrep" on \
      "firefox" "Firefox (browser)" on
      "qutebrowser" "Qutebrowser (browser)" on
      "vifm" "vifm (terminal file manager)" on
      "gtk" "GTK 3 themes and icons" on
      "programming" "Programming environments (PHP, Ruby, Go, Docker, Clojure)" on
      "keepass" "KeepassX" on
      "sql" "Mysql (mariadb) & mysql tools" on
      "jrnl" "Simple CLI journal" on
      "joplin" "Note taking system" off
      "thunar" "Graphical file manager" off
      "thunderbird" "Thunderbird" off
      "graphism" "Design" off
      "pandoc" "Pandoc and usefull dependencies" off
      "office" "Office tools (Libreoffice...)" off
      "vmware" "Vmware tools" off
      "language" "Language tools" off
      "multimedia" "Multimedia" off
      "nextcloud" "Nextcloud client" off
      "network" "Network Configuration" off
      "hugo" "Hugo static site generator" off
      "freemind" "Freemind - mind mapping software" off
      "doublecmd" "Double Commander - File explorer a la FreeCommander" off
      "photography" "Photography tools" off
      "gaming" "Almost everything for gaming on Linux" off)

dialog --checklist "You can now choose the groups of applications you want to install, according to your own CSV file.\n\n Press SPACE to select and ENTER to validate your choices." 0 0 0 "${apps[@]}" 2> app_choices
choices=$(cat app_choices) && rm app_choices

selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
final_apps=$(echo "$lines" | awk -F, '{print $2}')

echo "$selection" "$lines" "$count" >> "$output"

if [ "$dry_run" = false ]; then
    pacman -Syu --noconfirm >> "$output"
fi

rm -f /tmp/aur_queue

dialog --title "Let's go!" --msgbox \
"The system will now install everything you need.\n\n\
It will take some time.\n\n " 13 60

c=0
echo "$final_apps" | while read -r line; do
    c=$(( "$c" + 1 ))

    dialog --title "Arch Linux Installation" --infobox \
    "Downloading and installing program $c out of $count: $line..." 8 70

    if [ "$dry_run" = false ]; then
        pacman_install "$line"

        # Needed if system installed in VMWare
        if [ "$line" = "open-vm-tools" ]; then
            systemctl enable vmtoolsd.service
            systemctl enable vmware-vmblock-fuse.service
        fi

        if [ "$line" = "networkmanager" ]; then
            # Enable the systemd service NetworkManager.
            systemctl enable NetworkManager.service
        fi

        if [ "$line" = "zsh" ]; then
            # zsh as default terminal for user
            chsh -s "$(which zsh)" "$name"
        fi

        if [ "$line" = "docker" ]; then
            groupadd docker
            gpasswd -a "$name" docker
            systemctl enable docker.service
        fi

        if [ "$line" = "at" ]; then
            systemctl enable atd.service
        fi

        if [ "$line" = "mariadb" ]; then
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
        fi
    else
        fake_install "$line"
    fi
done

curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_user.sh > /tmp/install_user.sh;
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/sudoers > /etc/sudoers

dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40
if [ "$dry_run" = false ]; then
    # Change user and begin the install use script
    sudo -u "$name" sh /tmp/install_user.sh
    rm -f /tmp/install_user.sh
fi

rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

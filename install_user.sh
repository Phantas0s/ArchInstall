#!/bin/bash

run() {
    output="/home/$(whoami)/install_log"
    cd /tmp

    log INFO "FETCH VARS FROM FILES" "$output"
    # dry_run=$(cat /var_dry_run)

    log INFO "CREATE DIRECTORIES" "$output"
    create-directories
    log INFO "INSTALL YAY" "$output"
    install-yay "$output"
    log INFO "INSTALL AUR APPS" "$output"
    install-aur-apps "$output"
    log INFO "INSTALL DOTFILES" "$output"
    install-dotfiles
}

log() {
    local -r level=${1:?}
    local -r message=${2:?}
    local -r output=${3:?}
    local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "${timestamp} [${level}] ${message}" >>"$output"
}

create-directories() {
    mkdir -p "/home/$(whoami)/Documents"
    mkdir -p "/home/$(whoami)/Downloads"

    mkdir -p "/home/$(whoami)/workspace"
    mkdir -p "/home/$(whoami)/composer"

    command -v "go" >/dev/null && mkdir -p "/home/$(whoami)/workspace/go/bin"
    command -v "go" >/dev/null && mkdir -p "/home/$(whoami)/workspace/go/pkg"
    command -v "go" >/dev/null &&  mkdir -p "/home/$(whoami)/workspace/go/src"

    command -v "nextcloud" >/dev/null && mkdir -p "/home/$(whoami)/Nextcloud"
}

install-yay() {
    local -r output=${1:?}

    dialog --infobox "[$(whoami)] Installing \"yay\", an AUR helper..." 10 60
    aur-check "$output" yay
}

install-aur-apps() {
    local -r output=${1:?}

    count=$(wc -l < /tmp/aur_queue)
    c=0
    cat /tmp/aur_queue | while read -r prog
    do
        c=$(( "$c" + 1 ))
        dialog --infobox "[$(whoami)] AUR install - Downloading and installing program $c out of $count: $prog..." 10 60
        aur-check "$output" "$prog"
    done
}

#Install an AUR package manually.
aur-install() {
    local -r app=${1:?}

    curl -O "https://aur.archlinux.org/cgit/aur.git/snapshot/$app.tar.gz" \
    && tar -xvf "$app.tar.gz" \
    && cd "$app" \
    && makepkg --noconfirm -si \
    && cd - \
    && rm -rf "$app" "$app.tar.gz" ;
}

# aur_check runs on each of its arguments
# if the argument is not already installed
# it either uses yay to install it
# or installs it manually.
aur-check() {
    local -r output=${1:?}
    shift 1

    qm=$(pacman -Qm | awk '{print $1}')
    for arg in "$@"
    do
        if [[ "$qm" != *"$arg"* ]]; then
            yay --noconfirm -S "$arg" &>> "$output" || aur-install "$arg" &>> "$output"
        fi
    done
}

install-dotfiles() {
    DOTFILES="/home/$(whoami)/.dotfiles"
    if [ ! -d "$DOTFILES" ];
        then
            dialog --infobox "[$(whoami)] Downloading .dotfiles..." 10 60
            git clone --recurse-submodules "https://github.com/Phantas0s/.dotfiles" "$DOTFILES" >/dev/null
    fi

    source "/home/$(whoami)/.dotfiles/zsh/zshenv"
    cd "$DOTFILES"
    command -v "zsh" >/dev/null && zsh ./install.sh -y
}

run "$@"

# Phantas0s Arch Install

[![Mousless Development Environment](screen_780.png)](screen.png)

This is my scripts to install easily Arch Linux.

**WARNING**: This set of script should be used for inspiration, don't run them on your system. If you want to try to install everything (I would advise you to use a VM) you have to 

1. `curl` the first script `install_sys.sh` (`curl -LO https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_sys.sh && sh install_sys.sh`)
2. Change the function `url_installer` in the file if you want to.
3. Launch it.

Then, follow the instructions. Don't expect a lot of choices though.

## What's in there? 

Every scripts are called from `install_sys.sh`.

The first script `install_sys`.sh will:
1. Erase everything on the disk of your choice
2. Create partitions
    - Boot partition of 200M
    - Swap partition
    - Root partition

The second script `install_chroot` will:
1. Set up locale / time
2. Set up Grub for the boot

The third script `install_apps` will:
1. Create a new user with password
2. Install every software specified in `progs.csv`
3. Install `composer` (PHP package manager)

The fourth script `install_user` will:
1. Try to install every software not found by pacman with yay (AUR repos)
2. Install my [dotfiles](https://github.com/Phantas0s/.dotfiles)

## What software are installed?

Opening `apps.csv` will answer your question.

## Building Your Mouseless Development Environment

Switching between a keyboard and mouse costs cognitive energy. [My book will help you set up a Linux-based development environment](https://themouseless.dev) that keeps your hands on your keyboard. Take the brain power you've been using to juggle input devices and focus it where it belongs: on the things you create.

You'll learn how to write your own installation scripts too!

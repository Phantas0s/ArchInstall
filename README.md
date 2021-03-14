# Phantas0s Arch Install

[![Mousless Development Environment](screen_780.png)](screen.png)

This is my scripts to install my whole Mouseless Development Environment.

**WARNING**: This set of script should be used for inspiration, don't run them on your system.

If you want to know how it works, [I'm writing a book](https://themouseless.dev) which will explain that, and many other things.

If you want to try to install everything (I would advise you to use a Virtual Machine like VirtualBox), you just have to `curl` the first script `install_sys.sh` and run it.

`curl -O https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_sys.sh && sh install_sys.sh`

Follow the instructions. Don't expect a many choices though.

## What's in there? 

The first script `install_sys`.sh will:
1. Erase everything on one of your hard disk
2. Create partitions
    - Boot partition of 512M
    - Swap partition
    - Root partition

The second script `install_chroot` will:
1. Set up locale / time
2. Set up Grub for the boot
3. Create a user

The third script `install_apps` will:
1. Install every software specified in `apps.csv`

The fourth script `install_user` will:
1. Try to install every software not found by `pacman` with `yay` (AUR)
2. Install my [dotfiles](https://github.com/Phantas0s/.dotfiles)

## What software are installed?

Everything in apps.csv

## Building Your Mouseless Development Environment

Switching between a keyboard and mouse costs cognitive energy. [My book will help you set up a Linux-based development environment](https://themouseless.dev) that keeps your hands on your keyboard. Take the brain power you've been using to juggle input devices and focus it where it belongs: on the things you create.

You'll learn how to write your own installation scripts too!

#!/bin/bash

# inspired by aui
# to install: wget ow.ly/wnFgh -O aui.zip && mkdir aui && bsdtar -x -f aui.zip -C aui

pacman -S --noconfirm dialog

RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

dialog --defaultno --title "Are you sure?" --yesno "This is my personnal arch linux install. \n\n\
    It will just destroy everything on your hard disk (/dev/sda). \n\n\
    Don't say YES if you are not sure about what your are doing! \n\n\
    Are you sure?"  15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp

dialog --no-cancel --inputbox "You need four partitions: Boot, Swat, Root and Home. \n\n\
    Boot will be 200M.\n\n\
    Enter partitionsize in gb, separated by space for swap & root.\n\n\
    Home will take the rest of space available" 15 60 2>psize

IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    # SIZE=(12 25);
    SIZE=(2 4);
fi

timedatectl set-ntp true

#o - create a new MBR partition table / clear all partition data!
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit

cat <<EOF | fdisk /dev/sda
o
n
p


+200M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

#mkfs.ext4 /dev/sda4
#mkdir /mnt/home
# Encrypt home
cryptsetup --cipher aes-xts-plain64\
    --key-size 512\
    --hash sha512\
    --iter-time 5000\
    --use-random\
    luksFormat\
    --type luks2\
    /dev/sda4
    /etc/luks-keys/home

cryptsetup -d /etc/luks-keys/home open /dev/sda4 home

mkfs.ext4 /dev/mapper/home
mkdir /mnt/home
mount /dev/mapper/home /mnt/home

mkdir -m 700 /etc/luks-keys
dd if=/dev/random of=/etc/luks-keys/home bs=1 count=256

echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab

genfstab -U /mnt >> /mnt/etc/fstab
echo "/dev/mapper/home      /mnt/home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab

pacstrap /mnt base base-devel

curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_chroot.sh > /mnt/install_chroot.sh && arch-chroot /mnt bash install_chroot.sh && rm /mnt/install_chroot.sh

cat comp > /mnt/etc/hostname && rm comp

dialog --defaultno --title "Final Qs" --yesno "Eject CD/ROM (if any)?"  5 30 && eject
dialog --defaultno --title "Final Qs" --yesno "Reboot computer?"  5 30 && reboot
dialog --defaultno --title "Final Qs" --yesno "Return to chroot environment?"  6 30 && arch-chroot /mnt
clear

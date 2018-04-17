#!/bin/bash

pacman -S --noconfirm dialog

RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

dialog --defaultno --title "Are you sure?" --yesno "This is my personnal arch linux install. \n\nIt will just destroy everything on your hard disk. \n\nDon't say YES if you are not sure about what your are doing! \n\nAre you sure?"  15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 15 60 2> comp

dialog --no-cancel --inputbox "You need four partitions: Boot, Swat, Root and Home. \n\n Boot will be 200M.\n\n Enter partitionsize in gb, separated by space for swap & root. \n\n Home will take the rest" 15 60 2>psize

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

dialog --title "Partition" --msgbox "Creation of the partition table on the disk." 10 60

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

dialog --title "Partition" --msgbox "Formatting partition..." 10 60

mkfs.ext4 /dev/sda4
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda4 /mnt/home

dialog --title "Install" --msgbox "Installation of the system..." 10 60
pacstrap /mnt base base-devel

dialog --title "Install" --msgbox "Fstab generation..." 10 60
genfstab -U /mnt >> /mnt/etc/fstab

curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/chroot.sh > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

cat comp > /mnt/etc/hostname && rm comp

dialog --defaultno --title "Final Qs" --yesno "Eject CD/ROM (if any)?"  5 30 && eject
dialog --defaultno --title "Final Qs" --yesno "Reboot computer?"  5 30 && reboot
dialog --defaultno --title "Final Qs" --yesno "Return to chroot environment?"  6 30 && arch-chroot /mnt
clear

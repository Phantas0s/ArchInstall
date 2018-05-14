#!/bin/bash

# inspired by aui
# to install: wget ow.ly/wnFgh -O aui.zip && mkdir aui && bsdtar -x -f aui.zip -C aui

dialog --defaultno --title "Are you sure?" --yesno "This is my personnal arch linux install. \n\n\
    It will just DESTROY EVERYTHING on your hard disk (/dev/sda). \n\n\
    Don't say YES if you are not sure about what your are doing! \n\n\
    Are you sure?"  15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp

hderaser=$(dialog --no-cancel \
--title "!!! DELETE EVERYTHING !!!" \
--menu "Choose the way to destroy everything on your hard disk (/dev/sda)" 15 60 4 \
1 "Use dd" \
2 "Use schred" \
3 "No need - my hard disk is empty" --output-fd 1)

dialog --no-cancel --inputbox "You need four partitions: Boot, Swap, Root and Home. \n\n\
    Boot will be 200M.\n\n\
    Enter partitionsize in gb, separated by space for root & swap.\n\n\
    If you dont enter anything: \n\
    root -> 40G \n\
    swap -> 16G \n\n\
    Home will take the rest of the space available" 20 60 2> psize

IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(40 16);
fi

dialog --infobox "Formatting /dev/sda..." 4 40

case $hderaser in
	1) dd if=/dev/zero of=/dev/sda status=progress;;
	2) shred -v /dev/sda;;
    3) ;;
esac

dialog --infobox "Creating partitions..." 4 40

timedatectl set-ntp true

#o - create a new MBR partition table
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


+${SIZE[1]}G
n
p


+${SIZE[0]}G
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

# mkfs.ext4 /dev/sda4
# mkdir /mnt/home
# Encrypt home

dialog --infobox "Encrypt /home partition..." 4 40

mkdir /mnt/etc/
mkdir -m 700 /mnt/etc/luks-keys
dd if=/dev/random of=/mnt/etc/luks-keys/home bs=1 count=256
cat << EOF | cryptsetup --cipher aes-xts-plain64\
    --key-size 512\
    --hash sha512\
    --iter-time 5000\
    --use-random\
    luksFormat\
    /dev/sda4 \
    /mnt/etc/luks-keys/home
YES
EOF

cryptsetup -d /mnt/etc/luks-keys/home open /dev/sda4 home

mkfs.ext4 /dev/mapper/home
mkdir /mnt/home
mount /dev/mapper/home /mnt/home

pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab

### Continue installation
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_chroot.sh > /mnt/install_chroot.sh && arch-chroot /mnt bash install_chroot.sh \
    && rm /mnt/install_chroot.sh

cat comp > /mnt/etc/hostname \
    && rm comp


dialog --title "Reboot time" \
--yesno "Congrats! The install is done! \n\nTo run the new graphical environment, you need to restart your computer, log in and type \"startx\" \n\n You should restart your computer before trying your new shiny system. Do you want to restart now?" 20 60

response=$?
case $response in
   0) reboot;;
   1) clear;;
esac

clear

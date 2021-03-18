#!/bin/bash

# Defaults related to Git repositories
GITHUB_INSTALLER_USER=bimmerr2019
GITHUB_INSTALLER_NAME=ArchInstall
GITHUB_DOTFILES_USER=bimmerr2019
GITHUB_DOTFILES_NAME=dotfiles


dry_run=${dry_run:-false}
# TODO redirect output?
output=${output:-/tmp/arch-install-logs}
while getopts d:o: option
do
    case "${option}"
        in
        d) dry_run=${OPTARG};;
        o) output=${OPTARG};;
        *);;
    esac
done

pacman -Sy
pacman --noconfirm -S dialog

dialog --defaultno \
    --title "Are you sure?" \
    --yesno "This is my personnal arch linux install. \n\n\
    It will just DESTROY EVERYTHING on the hard disk of your choice. \n\n\
    Don't say YES if you are not sure about what you're doing! \n\n\
    Are you sure?"  15 60 || exit

# Change and save defaults to a file so we can load
# Defaults for Installer
dialog --no-cancel --inputbox "Enter name of GitHub user for installer." 10 60 "$GITHUB_INSTALLER_USER" 2> temp_text
GITHUB_INSTALLER_USER=$(cat temp_text) && rm temp_text
dialog --no-cancel --inputbox "Enter name of GitHub project for installer." 10 60 "$GITHUB_INSTALLER_NAME" 2> temp_text
GITHUB_INSTALLER_NAME=$(cat temp_text) && rm temp_text
# Defaults for Dotfiles
dialog --no-cancel --inputbox "Enter name of GitHub user for dotfiles." 10 60 "$GITHUB_DOTFILES_USER" 2> temp_text
GITHUB_DOTFILES_USER=$(cat temp_text) && rm temp_text
dialog --no-cancel --inputbox "Enter name of GitHub project for dotfiles." 10 60 "$GITHUB_DOTFILES_NAME" 2> temp_text
GITHUB_DOTFILES_NAME=$(cat temp_text) && rm temp_text

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> hn
hostname=$(cat hn) && rm hn

# Verify boot (UEFI or BIOS)
uefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && uefi=1

# Find and display available disks where Arch Linux can be installed
devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' | grep -E 'sd|hd|vd|nvme|mmcblk'))
dialog --title "Choose your hard drive" --no-cancel --radiolist \
    "Where do you want to install your new system?\n\n\
    Select with SPACE, valid with ENTER.\n\n\
    WARNING: Everything will be DESTROYED on the hard disk!" 15 60 4 "${devices_list[@]}" 2> hd
hd=$(cat hd); rm hd

default_size="8"
dialog --no-cancel --inputbox "You need four partitions: Boot, Root and Swap \n\
    The boot will be 512M\n\
    The root will be the rest of the hard disk\n\
    Enter partitionsize in gb for the Swap. \n\n\
    If you dont enter anything: \n\
        swap -> ${default_size}G \n\n" 20 60 2> swap_size
size=$(cat swap_size) && rm swap_size

[[ $size =~ ^[0-9]+$ ]] || size=$default_size

dialog --no-cancel \
    --title "!!! DELETE EVERYTHING !!!" \
    --menu "Choose the way to destroy everything on your hard disk ($hd)" 15 60 4 \
    1 "Use dd (wipe all disk)" \
    2 "Use schred (slow & secure)" \
    3 "No need - my hard disk is empty" 2> eraser

hderaser=$(cat eraser); rm eraser

function eraseDisk() {
    case $1 in
        1) dd if=/dev/zero of="$hd" status=progress 2>&1 | dialog --title "Formatting $hd..." --progressbox --stdout 20 60;;
        2) shred -v "$hd" | dialog --title "Formatting $hd..." --progressbox --stdout 20 60;;
        3) ;;
    esac
}

if [[ "$dry_run" = false ]]; then
    eraseDisk "$hderaser"
    timedatectl set-ntp true
fi

boot_partition_type=1
[[ "$uefi" == 0 ]] && boot_partition_type=4

if [[ "$dry_run" = false ]]; then

#g - create non empty GPT partition table
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit
partprobe "$hd"
fdisk "$hd" <<EOF
g
n


+512M
t
$boot_partition_type
n


+${size}G
n



w
EOF
partprobe "$hd"

mkswap "${hd}2"
swapon "${hd}2"

mkfs.ext4 "${hd}3"
mount "${hd}3" /mnt

if [ "$uefi" = 1 ]; then
    mkfs.fat -F32 "${hd}1"
    mkdir -p /mnt/boot/efi
    mount "${hd}"1 /mnt/boot/efi
fi

pacstrap /mnt base base-devel linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

# Save some variables in files for next script
echo "$uefi" > /mnt/var_uefi
echo "$hd" > /mnt/var_hd
echo "$hostname" > /mnt/hostname
echo 'export GITHUB_INSTALLER_USER='"$GITHUB_INSTALLER_USER" >/mnt/github_defaults
echo 'export GITHUB_INSTALLER_NAME='"$GITHUB_INSTALLER_NAME" >>/mnt/github_defaults
echo 'export GITHUB_DOTFILES_USER='"$GITHUB_DOTFILES_USER" >>/mnt/github_defaults
echo 'export GITHUB_DOTFILES_NAME='"$GITHUB_DOTFILES_NAME" >>/mnt/github_defaults

### Continue installation
curl https://raw.githubusercontent.com/$GITHUB_INSTALLER_USER/$GITHUB_INSTALLER_NAME/master/install_chroot.sh > /mnt/install_chroot.sh
arch-chroot /mnt bash install_chroot.sh

rm /mnt/var_uefi
rm /mnt/var_hd
rm /mnt/install_chroot.sh
rm /mnt/hostname
rm /mnt/github_defaults

fi

dialog --title "Reboot time" \
    --yesno "Congrats! The install is done! \n\nTo run the new graphical environment, you need to restart your computer. \n\nDo you want to restart now?" 20 60

response=$?
case $response in
    0) reboot;;
    1) clear;;
esac

clear

#!/bin/bash

# TODO redirect output
dry_run=${dry_run:-false}
output=${output:-/tmp/arch-install-logs}
while getopts d:o: option
do
    case "${option}"
        in
        d) dry_run=${OPTARG};;
        o) output=${OPTARG};;
    esac
done

dialog --defaultno --title "Are you sure?" --yesno "This is my personnal arch linux install. \n\n\
    It will just DESTROY EVERYTHING on the hard disk of your choice. \n\n\
    Don't say YES if you are not sure about what your are doing! \n\n\
    Are you sure?"  15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp

hd=${hd:-/dev/sda}
select_device() {
    devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " off"}' | grep -E 'sd|hd|vd|nvme|mmcblk' | sed -e "s/off/on/"))
    hd=$(dialog --title "Choose your hard drive" \
        --radiolist --stdout "Where do you want to install your new system?\n\nSelect with SPACE.\n\nWARNING: Everything will be DESTROYED on the hard disk!" 15 60 4 ${devices_list[@]} --output-fd 1)
}

select_device

hderaser=$(dialog --no-cancel \
    --title "!!! DELETE EVERYTHING !!!" \
    --menu "Choose the way to destroy everything on your hard disk ($hd)" 15 60 4 \
    1 "Use dd (wipe all disk)" \
    2 "Use schred (slow & secure)" \
    3 "No need - my hard disk is empty" --output-fd 1)

dialog --no-cancel --inputbox "You need four partitions: Boot, Swap, Root and Home. \n\n\
    Boot will be 200M.\n\n\
    Enter partitionsize in gb, separated by space for root & swap.\n\n\
    If you dont enter anything: \n\
        root -> 60G \n\
        swap -> 16G \n\n\
        Home will take the rest of the space available" 20 60 2> psize

IFS=' ' read -ra SIZE <<< $(cat psize)

number='^[0-9]+$'
if ! [[ ${#SIZE[@]} -eq 2 ]] || ! [[ ${SIZE[0]} =~ $number ]] || ! [[ ${SIZE[1]} =~ $number ]] ; then
    SIZE=(60 16);
fi

function eraseDisk() {
    case $1 in
        1) dd if=/dev/zero of=$hd status=progress 2>&1 | dialog --title "Formatting $hd..." --progressbox --stdout 20 60;;
        2) shred -v $hd | dialog --title "Formatting $hd..." --progressbox --stdout 20 60;;
        3) ;;
    esac
}


if [ "$dry_run" != true ]; then
    eraseDisk hderaser
fi

dialog --infobox "Creating partitions..." 4 40

timedatectl set-ntp true

if [ "$dry_run" != true ]; then
#o - create a new MBR partition table
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit
cat <<EOF | fdisk $hd
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

mkfs.ext4 "${hd}3"
mkfs.ext4 "${hd}1"

mkswap "${hd}2"
swapon "${hd}2"

mount "${hd}3" /mnt
mkdir /mnt/boot
mount "${hd}1" /mnt/boot

# to comment to come back to home partition encrypted
mkfs.ext4 "${hd}4"
mkdir /mnt/home
mount "${hd}4" /mnt/home

# dialog --infobox "Encrypt /home partition..." 4 40

# mkdir /mnt/etc/
# mkdir -m 700 /mnt/etc/luks-keys
# dd if=/dev/random of=/mnt/etc/luks-keys/home bs=1 count=256
# cat << EOF | cryptsetup --cipher aes-xts-plain64\
#     --key-size 512\
#     --hash sha512\
#     --iter-time 5000\
#     --use-random\
#     luksFormat\
#     /dev/sda4 \
#     /mnt/etc/luks-keys/home
# YES
# EOF

# cryptsetup -d /mnt/etc/luks-keys/home open /dev/sda4 home

# mkfs.ext4 /dev/mapper/home
# mkdir /mnt/home
# mount /dev/mapper/home /mnt/home

pacstrap /mnt base base-devel linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

### Continue installation
curl https://raw.githubusercontent.com/Phantas0s/ArchInstall/master/install_chroot.sh > /mnt/install_chroot.sh
arch-chroot /mnt bash install_chroot.sh
rm /mnt/install_chroot.sh

cat comp > /mnt/etc/hostname \
    && rm comp
fi

dialog --title "Reboot time" \
    --yesno "Congrats! The install is done! \n\nTo run the new graphical environment, you need to restart your computer. \n\nDo you want to restart now?" 20 60

response=$?
case $response in
    0) reboot;;
    1) clear;;
esac

clear

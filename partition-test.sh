dialog --no-cancel --inputbox "You need four partitions: Boot, Swat, Root and Home. \n\n Boot will be 200M.\n\n Enter partitionsize in gb, separated by space for swap & root. \n\n Home will take the rest" 10 60 2>psize

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

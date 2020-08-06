# LUCKS encryption (install_sys when formatting partitions)

# home
# mkfs.ext4 "${hd}4"
# mkdir /mnt/home
# mount "${hd}4" /mnt/home

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

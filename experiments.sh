#
#
# +-----------------------------------------------------------+
# | LUCKS encryption (install_sys when formatting partitions) |
# +-----------------------------------------------------------+
#
#

# home
# mkfs.ext4 "${hd}4"
# mkdir /mnt/home
# mount "${hd}4" /mnt/home

# Worked more or less, but I had problems when reading fstab (if I remember correctly...)

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

# In install_chroot

# For encrypted home
# sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/sda4:crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda4:crypt"/g' /etc/default/grub

# To boot with encrypted home
# echo "home /dev/sda4 /etc/luks-keys/home" >> /etc/crypttab
# echo "/dev/mapper/home      /home               ext4    defaults,errors=remount-ro  0  2" >> /etc/fstab


#######################





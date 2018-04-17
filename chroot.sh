#Potential variables: timezone, lang and local

passwd

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

# Install netctl (from arch iso base) ?
# TODO take care of the network management

pacman --noconfirm --needed -S grub && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

pacman --noconfirm --needed -S dialog

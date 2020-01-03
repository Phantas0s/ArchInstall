#!/bin/bash

# To debug in chroot environment

mount /dev/sda3 /mnt
mount /dev/sda1 /mnt/boot
mount /dev/sda4 /mnt/home

arch-chroot /mnt

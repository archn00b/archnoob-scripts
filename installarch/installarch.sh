#!usr/bin/env bash

# UPDATING SYSYTEM CLOCK
timedatectl

# YOU HAVE TO INSTALL GIT WITH PACMAN -SY GIT 

# FORMATING DISK
fdisk /dev/vda << EOF
g
n


+1000M
t
1
n


+4000M
t

19
n



w
EOF 

# FORMATTING THE SYSTEM
mkfs.fat -F 32 /dev/vda1
mkswap /dev/vda2
mkfs.ext4 /dev/vda3

# MOUNTING THE FILE SYSTEM
mount /dev/vda3 /mnt
mount --mkdir /dev/vda1 /mnt/boot
swapon /dev/vda2

# INSTALLING BASE OF LINUX
pacstrap -K /mnt base linux linux-firmware 

# CONFIGURING THE SYSTEM
genfstab -U /mnt >> /mnt/etc/fstab

# CHROOT INTO THE SYSTEM
arch-chroot /mnt

# SETTNG TIMEZONE
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# LOCALIZATION
sed -i '178s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# NETWORK CONFIGURATION
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
sleep 1
pacman -S networkmanager
systemctl enable NetworkManager

# SETTING ROOT PASSWROD
`echo root:123 | chpasswd`

# INSTALLING BOOTLOADER AND CONFIGURATION
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"


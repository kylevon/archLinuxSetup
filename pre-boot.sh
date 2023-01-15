#!/bin/zsh

# Wifi running:

rfkill unblock wlan
ip link set wlan0 up
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect Chamonix
# <Password>
exit

# Setup correct timezone
# To find timezone:
# timedatectl list-timezones | grep "Chile"
timedatectl set-timezone Chile/Continental
# timedatectl status to check if correct.

# Partitions

fdisk -l

fdisk /dev/nvme0n1

# m for help to see commands
g # to create a GPT partition table
n # to create a new partition
1 # to create the first partition
# default for first sector (press enter)
+550M # to set the size of the partition (EFI)
n # Now we create the swap
2
# default for first sector (press enter)
+11G # to set the size of the partition (swap) recommendation from https://itsfoss.com/swap-size/
n # Now we create the data patition
3
# default for first sector (press enter)
# default for last sector (press enter)
# Now we change partition types
t # to change partition type
1 # to select the first partition
1 # to select EFI
t # to change partition type of the second partition
2 # to select the second partition
19 # to select Linux swap
w
# Now we need to create the file systems.
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
# Now we mount the partitions
mount /dev/nvme0n1p3 /mnt
# Now we install the base system for arch:
pacstrap /mnt base base-devel linux linux-firmware
# base-devel is needed for compiling packages from AUR
# Now we generate the fstab file, which is the filesystem table.
genfstab -U /mnt >> /mnt/etc/fstab
# Now we chroot into the new system
arch-chroot /mnt
# Now we set the timezone
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime
# Set up hardware clock
hwclock --systohc
# We first install the newest version of neovim
pacman -S neovim
# Now we set the locale
# Uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen
nvim /etc/locale.gen
locale-gen
# Now we set the hostname
nvim /etc/hostname
# My name will be hermes
# Now we set the hosts file
nvim /etc/hosts
# We write at the end of the file:
# 127.0.0.1      localhost
# ::1            localhost
# 127.0.1.1      hermes

# Now we create the password
passwd
# Now we add one user
useradd -m kyle
# Now we need to make sure kyle is a member of the wheel group so that
# it can use sudo. Other groups I will want to add are:
# audio, video, storage, optical, network, scanner, power, wheel
usermod -aG wheel,audio,video,storage,optical,network,scanner,power kyle
pacman -S sudo
EDITOR=nvim
visudo
# After writing visudo, uncommend the line that talks about wheel priviledges
# now we install grub
pacman -S grub efibootmgr dosfstools os-prober mtools
mkdir /boot/EFI
mount /dev/nvme0n1p1 /boot/EFI
# Now we have to really install grub to the correct partition:
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck 
# Now we need to generate the grub config file
grub-mkconfig -o /boot/grub/grub.cfg
# Now we have installed arch linux.

# Now we start networking and git
pacman -S networkmanager git
# Now we enable systemctl
systemctl enable NetworkManager
# Now we exit the chroot
exit
umount -R /mnt
reboot

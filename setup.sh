#! /usr/bin/bash
echo "Starting Arch Linux Installation"
timedatectl
fdisk -l
fdisk /dev/sda
mkfs.btrfs /dev/sda7
mkfs.fat -F 32 /dev/sda5
mkswap /dev/sda6
swapon /dev/sda6
mount /dev/sda7 /mnt
mount --mkdir /dev/sda /mnt/boot
pacstrap -i /mnt base base-devel linux linux-headers linux-firmware intel-ucode sudo nano vim neofetch git networkmanager dhcpcd pulseaudio
genstab -o /mnt >> /mnt/etc/fstab
arch-chroot /mnt
passwd
echo "Enter username: "
read username
useradd -m $username
usermod -aG wheel storage, power $username
locale-gen
echo LANG=en_IN.UTF-8 > /etc/locale.conf
export LANG=en_IN.UTF-8
echo "Enter hostname: "
read hostname
echo $hostname > /etc/hostname
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
mkdir /boot/efi
mount /dev/sda2 /boot/efi
pacman -S os-prober
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub.grub.cfg
systemctl enable dhcp.service
systemctl enable NetworkManager.service
umount -lR /mnt
reboot

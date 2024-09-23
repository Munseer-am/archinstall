#! /bin/bash
# set time
echo "Setting time"
timedatectl

# list block  devices
lsblk

# take input
echo "Select disk: "
read DISK

# run partitioning tool
echo "Partition disk"
cfdisk $DISK

# take inputs for partitions
echo "Enter root partition: "
read ROOT
echo "Enter swap partiton: "
read SWAP
echo "Enter EFI partition"
read EFI

# create filesystem
echo "Creating filesystem"
mkfs.ext4 $ROOT
mkswap $SWAP
mkfs.fat -F 32 $EFI

# mount filesystem
echo "Mounting filesystem"
mount $ROOT /mnt
mount --mkdir $EFI /mnt/efi
swapon $SWAP

# rank mirrors
echo "Backing up pacman mirrorlist"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
pacman -Sy
pacman -S pacman-contrib --noconfirm
echo "Ranking mirrors"
rankmirrors -n 10 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist

# install base
echo "Installing the base system"
pacstrap -i /mnt base base-devel linux linux-headers linux-firmware intel-ucode sudo nano vim git neofetch networkmanager dhcpcd pulseaudio

# generate fstab
echo "Generating the fstab"
genfstab -U /mnt >> /mnt/fstab

# change root
echo "Changing root"
arch-chroot /mnt

# set root password
echo "Set root password"
passwd

# create user
echo "Creating user"
echo "Enter username"
read username
useradd -m $username
usermod -aG wheel,storage,power $username

# sudo
echo "Uncomment: %wheel ALL=(ALL)"
sleep 5
visudo

# generate locale
echo "Generating locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# set lang
echo "Setting lang"
echo LANG=en_IN.UTF8 > /etc/locale.conf
export LANG=en_IN.UTF8

# set hostname
echo "Setting hostname"
echo "Enter hostname"
read hostname

echo $hostname > /etc/hostname

echo "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname.localdomain\tlocalhost" > /etc/hosts

# set region
echo "Setting timezone and region"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# install bootloader
echo "INSTALLING BOOTLOADER"
mkdir /boot/efi
mount $EFI /boot/efi
pacmafn -S grub efibootmgr dosfstools mtools os-prober --noconfirm

grub-install --target=x86_64-efi --bootloader-id=$hostname --efi-directory=/boot --force
grub-mkconfig -o /boot/grub/grub.cfg

# enabling services
echo "Enabling services"
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable pulseaudio

# adding chaotic-aur
echo "Setting up chaotic aur"
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
pacman -Sy

# install wm
echo "Install window manager and other packages"
pacman -S hyprland waybar zsh kitty brave rofi wofi sddm bluez --noconfirm
systemctl enable sddm

umount -lR /mnt
reboot

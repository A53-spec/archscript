#!/bin/bash
#https://github.com/helmuthdu/aui


BOOT_PARTITION_SIZE=+1M
SWAP_PARTITION_SIZE=+2G

hostname=laptop
username=theo
rootpasswd=azerty
userpasswd=azerty

function Creation_partition() {
    #Partitionnement des disques
    #EFI partition
    {
    echo g # Create a new empty GPT partition table

    #BOOT PARTITION
    echo n # Add a new partition
    echo 1 # Partition number
    echo   # First sector (Accept default: 1)
    echo $BOOT_PARTITION_SIZE # 1MiB in size

    #SWAP PARTITION
    echo n # Add a new partition
    echo 2 # Partition number
    echo   # First sector (Accept default: 1)
    echo $SWAP_PARTITION_SIZE # 2GiB in size

    #Remainder PARTITION
    echo n # Add a new partition
    echo 3 # Partition number
    echo   # First sector (Accept default: 1)
    echo   # reste 

    #changement des types de partitions
    echo t
    echo 1 #choisi la partition 1
    echo 4 #change en type BIOS BOOT

    echo t
    echo 2 #choisi la partition 2
    echo 19 #change en type SWAP

    echo t
    echo 3 #choisi la partition 2
    echo 23 #change en type EFI

    echo w # Write changes
    } | fdisk /dev/sda

    echo "Partition des disques réussies"
    sleep 1
}


echo "Archlinux bash script"

#change le clavier qwerty en fr
loadkeys fr 
yes | pacman -Sy > /dev/null
yes | pacman -S reflector  > /dev/null
reflector --latest 5  --download-timeout 2 --sort rate --save /etc/pacman.d/mirrorlist > /dev/null
Creation_partition
#Formatage des partitions
yes | mkfs.ext4 /dev/sda3 > /dev/null
mkswap /dev/sda2
#activation de la partition d'échange
swapon /dev/sda2
#Montage des systèmes de fichiers
mount /dev/sda3 /mnt #partition racine
#Mise à jour de l'horloge système
timedatectl set-ntp true
#Installation des paquets essentiels
pacstrap -K /mnt base linux linux-firmware 
#Configuration du système
genfstab -U /mnt >> /mnt/etc/fstab

cat <<EOF >/mnt/part2.sh
#!/bin/bash
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/#fr_FR.UTF/fr_FR.UTF/g' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'LANGUAGE=en_US' >> /etc/locale.conf
echo 'KEYMAP=fr-latin1' >> /etc/vconsole.conf
echo $hostname >> /etc/hostname
echo -e '127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t'$hostname >> /etc/hosts
{
    echo $rootpasswd
    echo $rootpasswd
} | passwd
useradd -m $username
{
    echo $userpasswd
    echo $userpasswd
} | passwd $username
yes | pacman -S sudo > /dev/null
usermod -aG wheel,audio,video,optical,storage $username
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers 
yes | pacman -S grub > /dev/null
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
yes | pacman -S networkmanager vim git dhcpcd networkmanager network-manager-applet
systemctl enable sshd
systemctl enable dhcpcd
systemctl enable NetworkManager
yes | pacman -S iw wpa_supplica nt dialog intel-ucode git reflector lshw unzip htop
yes | pacman -S wget pulseaudio alsa-utils alsa-plugins pavucontrol xdg-user-dirs
exit #leave chroot 
EOF

arch-chroot /mnt /bin/bash part2.sh
umount -R /mnt 
swapoff /dev/sda2
#!/bin/bash

function Test_EFI_MODE(){
    #Test si on est en mode UEFI
    if ls /sys/firmware/efi/efivars > /dev/null 2>&1
    then
        echo "EFI"
        clear
    else
        clear
        echo "Pas le bon mode BIOS"
        sleep_sortir
    fi
}

function Creation_partition() {
    #Partitionnement des disques
    #EFI partition
    {
    echo g # Create a new empty GPT partition table

    #EFI PARTITION
    echo n # Add a new partition
    echo 1 # Partition number
    echo   # First sector (Accept default: 1)
    echo $EFI_PARTITION_SIZE # 550MiB in size

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
    echo 1 #change en type EFI

    echo t
    echo 2 #choisi la partition 2
    echo 19 #change en type EFI

    echo w # Write changes
    } | fdisk /dev/sda

    echo "Partition des disques réussies"
    sleep 1
    clear
}

echo "Begin Arch install script"
loadkeys fr-latin1
Test_EFI_MODE
Creation_partition
timedatectl status
#Formatage des partitions
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3
#Montage des systèmes de fichiers
mount /dev/sda3 /mnt #partition racine
mount --mkdir /dev/sda1 /mnt/boot
#activation de la partition d'échange
swapon /dev/sda2
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
echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf
echo 'KEYMAP=fr-latin1' > /etc/vconsole.conf
echo $hostname > /etc/hostname
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
usermod -aG wheel,audio,video,optical,storage $username
pacman -S sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers 
pacman -S grub efibootmgr dosfstools os-prober
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI/
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S networkmanager vim git
systemctl enable NetworkManager
exit #leave chroot 
EOF

arch-chroot /mnt /bin/bash part2.sh

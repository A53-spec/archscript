#!/bin/bash
#https://github.com/helmuthdu/aui


EFI_PARTITION_SIZE=+550M
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
}


echo "Archlinux bash script"

#change le clavier qwerty en fr
loadkeys fr 
yes | pacman -Sy > /dev/null
yes | pacman -S reflector  > /dev/null
reflector --latest 5  --download-timeout 2 --sort rate --save /etc/pacman.d/mirrorlist > /dev/null
Creation_partition
#Formatage des partitions
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
yes | mkfs.ext4 /dev/sda3 > /dev/null
#Montage des systèmes de fichiers
mount /dev/sda3 /mnt #partition racine
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
#activation de la partition d'échange
swapon /dev/sda2
#Mise à jour de l'horloge système
timedatectl set-ntp true
#Installation des paquets essentiels
yes | pacstrap /mnt base linux linux-firmware > /dev/null 
#Configuration du système
genfstab -U /mnt >> /mnt/etc/fstab


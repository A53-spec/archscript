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

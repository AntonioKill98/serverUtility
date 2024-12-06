#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per verificare e installare il supporto per filesystem
check_filesystem_support() {
    declare -A FS_PACKAGES=(
        ["ntfs"]="ntfs-3g"
        ["btrfs"]="btrfs-progs"
        ["xfs"]="xfsprogs"
        ["exfat"]="exfatprogs"
        ["vfat"]="dosfstools"
        ["fat32"]="dosfstools"
        ["nfs"]="nfs-common"
        ["cifs"]="cifs-utils"
        ["hfs+"]="hfsplus"
    )

    for FS in "${!FS_PACKAGES[@]}"; do
        PACKAGE=${FS_PACKAGES[$FS]}
        if ! dpkg -l | grep -q "$PACKAGE"; then
            apt update -qq && apt install -y "$PACKAGE" > /dev/null
        fi
    done
}

# Funzione per visualizzare i dischi in formato tabella
list_disks() {
    # Header della tabella
    printf "╔═════════════════╦═══════════════════════════╦════════════════╦═════════════════╦══════════════════╦════════════════════════════════╗\n"
    printf "║ %-15s ║ %-25s ║ %-14s ║ %-15s ║ %-16s ║ %-30s ║\n" "Nome" "Label" "Dimensione" "Filesystem" "Stato" "MountPoint"
    printf "╠═════════════════╬═══════════════════════════╬════════════════╬═════════════════╬══════════════════╬════════════════════════════════╣\n"

    # Ottieni informazioni sui dischi in formato chiave=valore
    lsblk -P -o NAME,LABEL,SIZE,FSTYPE,MOUNTPOINT | while IFS= read -r line; do
        # Estrai i campi in base ai loro nomi
        name=$(echo "$line" | grep -oP 'NAME="\K[^"]+')
        label=$(echo "$line" | grep -oP 'LABEL="\K[^"]*')
        size=$(echo "$line" | grep -oP 'SIZE="\K[^"]+')
        fstype=$(echo "$line" | grep -oP 'FSTYPE="\K[^"]*')
        mountpoint=$(echo "$line" | grep -oP 'MOUNTPOINT="\K[^"]*')

        # Rimuove prefissi non necessari dai nomi dei dischi
        name=$(echo "$name" | sed 's/^[├─|└─]*//')

        # Escludi dischi senza filesystem valido
        if [[ -z "$fstype" || "$fstype" == "-" ]]; then
            continue
        fi

        # Imposta un placeholder per label se vuota
        label=${label:-"-"}

        # Stato del disco (montato o meno)
        if [[ -n "$mountpoint" && "$mountpoint" != "-" ]]; then
            state="MONTATO"
        else
            state="NON MONTATO"
            mountpoint="-"
        fi

        # Stampa la riga
        printf "║ %-15s ║ %-25s ║ %-14s ║ %-15s ║ %-16s ║ %-30s ║\n" \
            "$name" "$label" "$size" "$fstype" "$state" "$mountpoint"
    done

    # Footer della tabella
    printf "╚═════════════════╩═══════════════════════════╩════════════════╩═════════════════╩══════════════════╩════════════════════════════════╝\n"
}

# Funzione per montare un disco e renderlo permanente
mount_disk() {
    list_disks

    while true; do
        read -p "Inserisci il nome del dispositivo (es. sdb1) da montare o 'q' per uscire: " DEVICE
        if [[ "$DEVICE" == "q" ]]; then
            break
        elif lsblk -nro NAME | grep -qw "$DEVICE"; then
            FSTYPE=$(lsblk -no FSTYPE "/dev/$DEVICE")
            if [[ -z "$FSTYPE" ]]; then
                echo "Errore: Impossibile determinare il filesystem di /dev/$DEVICE. Verifica il disco."
                break
            fi
            read -p "Inserisci il percorso assoluto dove montare il disco (es. /mnt/disk): " MOUNTPOINT
            if [[ ! -d "$MOUNTPOINT" ]]; then
                mkdir -p "$MOUNTPOINT"
            fi
            mount -t "$FSTYPE" "/dev/$DEVICE" "$MOUNTPOINT"
            if [[ $? -eq 0 ]]; then
                echo "Il disco /dev/$DEVICE ($FSTYPE) è stato montato con successo in $MOUNTPOINT."
                # Aggiunta del montaggio permanente in fstab
                UUID=$(blkid -s UUID -o value "/dev/$DEVICE")
                if ! grep -q "$UUID" /etc/fstab; then
                    echo "UUID=$UUID $MOUNTPOINT $FSTYPE defaults 0 0" >> /etc/fstab
                    echo "Montaggio permanente aggiunto per $DEVICE in $MOUNTPOINT."
                fi
            else
                echo "Errore durante il montaggio di /dev/$DEVICE."
            fi
            break
        else
            echo "Dispositivo non valido. Inserisci il nome completo della partizione (es. sdb1)."
        fi
    done
}

# Funzione per smontare un disco e rimuoverlo da fstab
unmount_disk() {
    list_disks
    while true; do
        read -p "Inserisci il nome del dispositivo (es. sdb1) da smontare o 'q' per uscire: " DEVICE
        if [[ "$DEVICE" == "q" ]]; then
            break
        elif mount | grep -q "/dev/$DEVICE"; then
            MOUNTPOINT=$(lsblk -no MOUNTPOINT "/dev/$DEVICE")
            if [[ -n "$MOUNTPOINT" ]]; then
                umount "/dev/$DEVICE"
                if [[ $? -eq 0 ]]; then
                    echo "Il disco /dev/$DEVICE è stato smontato con successo."
                    # Rimuove il montaggio permanente da fstab
                    UUID=$(blkid -s UUID -o value "/dev/$DEVICE")
                    sed -i "\|UUID=$UUID|d" /etc/fstab
                    echo "Montaggio permanente rimosso per /dev/$DEVICE."
                    # Rimuove la directory di montaggio
                    rmdir "$MOUNTPOINT" && echo "La directory $MOUNTPOINT è stata rimossa."
                else
                    echo "Errore durante lo smontaggio di /dev/$DEVICE."
                fi
            else
                echo "Errore: Il dispositivo /dev/$DEVICE non è montato."
            fi
            break
        else
            echo "Dispositivo non valido o non montato. Riprova."
        fi
    done
}

# Funzione principale del menu
main_menu() {
    while true; do
        echo
        echo "Menu principale:"
        echo "1) Montare un disco (montaggio permanente)"
        echo "2) Elenco dischi"
        echo "3) Smontare un disco (rimozione permanente)"
        echo "4) Esci"
        read -p "Scegli un'opzione: " OPTION

        case $OPTION in
        1)
            mount_disk
            ;;
        2)
            list_disks
            ;;
        3)
            unmount_disk
            ;;
        4)
            echo "Uscita."
            break
            ;;
        *)
            echo "Opzione non valida. Riprova."
            ;;
        esac
    done
}

# Funzione principale
main() {
    check_root
    check_filesystem_support
    main_menu
}

# Esecuzione dello script
main

#!/bin/bash

# Verifica esecuzione come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Controllo e installazione del supporto NTFS
echo "Controllo del supporto NTFS nel sistema..."
if ! dpkg -l | grep -q "ntfs-3g"; then
    echo "Il supporto NTFS non è presente. Installazione del pacchetto ntfs-3g..."
    apt update && apt install -y ntfs-3g
else
    echo "Il supporto NTFS è già presente nel sistema."
fi

# Funzione per elencare i filesystem disponibili per il montaggio
list_filesystems() {
    echo "Filesystem disponibili nel sistema:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
}

# Funzione per montare un disco
mount_disk() {
    list_filesystems

    while true; do
        read -p "Inserisci il nome del dispositivo (es. sdb1) da montare o 'q' per tornare al menu: " DEVICE
        if [[ "$DEVICE" == "q" ]]; then
            break
        elif lsblk -o NAME | grep -q "^${DEVICE}$"; then
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
            else
                echo "Errore durante il montaggio di /dev/$DEVICE."
            fi
            break
        else
            echo "Dispositivo non valido. Riprova."
        fi
    done
}

# Funzione per mostrare i dischi montati
list_mounted_disks() {
    echo "Dischi attualmente montati:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -E "MOUNTPOINT|ext|ntfs|vfat|btrfs"
}

# Funzione per rendere permanente il montaggio
make_mounts_permanent() {
    echo "Configurazione del montaggio permanente..."
    while IFS= read -r line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        MOUNTPOINT=$(echo "$line" | awk '{print $4}')
        if [[ -n "$DEVICE" && -n "$MOUNTPOINT" ]]; then
            UUID=$(blkid -s UUID -o value "/dev/$DEVICE")
            FSTYPE=$(lsblk -no FSTYPE "/dev/$DEVICE")
            if ! grep -q "$UUID" /etc/fstab; then
                echo "UUID=$UUID $MOUNTPOINT $FSTYPE defaults 0 0" >> /etc/fstab
                echo "Aggiunto il montaggio permanente per $DEVICE ($MOUNTPOINT)."
            else
                echo "Il montaggio di $DEVICE ($MOUNTPOINT) è già permanente."
            fi
        fi
    done < <(lsblk -o NAME,FSTYPE,MOUNTPOINT | grep -E "ext|ntfs|vfat|btrfs")
    echo "Montaggi permanenti configurati."
}

# Menu principale
while true; do
    echo
    echo "Menu principale:"
    echo "1) Montare un disco"
    echo "2) Elenco dischi attualmente montati"
    echo "3) Rendi permanente il montaggio"
    echo "4) Esci"
    read -p "Scegli un'opzione: " OPTION

    case $OPTION in
    1)
        mount_disk
        ;;
    2)
        list_mounted_disks
        ;;
    3)
        make_mounts_permanent
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

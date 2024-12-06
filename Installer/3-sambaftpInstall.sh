#!/bin/bash

# Verifica se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Usa sudo."
        exit 1
    fi
}

# Funzione per aggiornare i pacchetti di sistema
update_system() {
    echo "Aggiornamento dei pacchetti..."
    apt update && apt upgrade -y
}

# Funzione per creare il gruppo "shareGroup" se non esiste
create_share_group() {
    echo "Creazione del gruppo '${SHARE_GROUP}'..."
    if ! getent group "${SHARE_GROUP}" > /dev/null; then
        groupadd "${SHARE_GROUP}"
        echo "Gruppo '${SHARE_GROUP}' creato con successo."
    else
        echo "Gruppo '${SHARE_GROUP}' già esistente."
    fi
}

# Funzione per verificare e installare pacchetti
install_package() {
    local package="$1"
    if dpkg -l | grep -q "^ii.*$package"; then
        echo "$package è già installato."
        read -p "Vuoi disinstallare $package e reinstallarlo? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            remove_package "$package"
        else
            echo "Salto la reinstallazione di $package."
            return
        fi
    fi
    echo "Installazione di $package..."
    apt install -y "$package"
}

# Funzione per rimuovere pacchetti e relativi file di configurazione
remove_package() {
    local package="$1"
    echo "Rimozione di $package..."
    apt purge -y "$package"
    apt autoremove -y
    case "$package" in
    samba)
        rm -rf /etc/samba
        rm -rf /var/lib/samba
        ;;
    vsftpd)
        rm -rf /etc/vsftpd*
        ;;
    esac
    echo "$package è stato rimosso."
}

# Funzione per configurare Samba
configure_samba() {
    echo "Configurazione di Samba..."
    local samba_conf="/etc/samba/smb.conf"
    local samba_share_dir="/pubShare_SAMBA"

    # Creazione del file di configurazione
    mkdir -p /etc/samba
    cat > "$samba_conf" <<EOF
[global]
workgroup = WORKGROUP
log file = /var/log/samba/log.%m
max log size = 1000
logging = file
panic action = /usr/share/samba/panic-action %d
server role = standalone server
obey pam restrictions = yes
security = user
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes
map to guest = bad user
guest account = nobody
usershare allow guests = yes

[homes]
create mask = 0700
directory mask = 0700
valid users = %S
browseable = NO
read only = no

[PublicShare]
comment = Cartella Pubblica
path = ${samba_share_dir}
browseable = yes
guest ok = yes
writable = yes
guest only = yes
force create mode = 0777
force directory mode = 0777
EOF

    # Creazione della directory condivisa
    mkdir -p "$samba_share_dir"
    chmod -R 0777 "$samba_share_dir"
    chown -R nobody:nogroup "$samba_share_dir"

    # Riavvio del servizio Samba
    systemctl restart smbd || echo "Errore durante il riavvio di smbd. Verifica l'installazione di Samba."
    check_service_status "smbd"
}

# Funzione per configurare vsftpd
configure_vsftpd() {
    echo "Configurazione di vsftpd..."
    local vsftpd_conf="/etc/vsftpd.conf"

    # Creazione del file di configurazione
    cat > "$vsftpd_conf" <<EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=\$USER
local_root=/home/\$USER
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
EOF

    # Creazione del file /etc/vsftpd.userlist
    echo "Creazione del file /etc/vsftpd.userlist..."
    touch /etc/vsftpd.userlist
    chmod 600 /etc/vsftpd.userlist

    # Riavvio del servizio vsftpd
    systemctl restart vsftpd || echo "Errore durante il riavvio di vsftpd. Verifica l'installazione di vsftpd."
    check_service_status "vsftpd"
}

# Funzione per verificare lo stato di un servizio
check_service_status() {
    local service="$1"
    systemctl is-active --quiet "$service"
    if [[ $? -eq 0 ]]; then
        echo "Il servizio $service è attivo."
    else
        echo "Il servizio $service non è attivo. Verifica la configurazione."
    fi
}

# Funzione principale
main() {
    check_root
    update_system

    # Installazione di Samba e configurazione
    install_package "samba"
    configure_samba

    # Installazione di vsftpd e configurazione
    install_package "vsftpd"
    configure_vsftpd

    create_share_group

    # Informazioni finali
    echo
    echo "Installazione completata!"
    echo "Samba è attivo con la condivisione 'PublicShare' raggiungibile su /pubShare_SAMBA."
    echo "Il server FTP è attivo sulle porte 20 (FTP) e 21 (FTP Control)."
    echo "Samba e FTP sono pronti per l'uso!"
}

# Esecuzione del main
main

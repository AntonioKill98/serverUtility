#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Aggiornamento dei pacchetti
echo "Aggiornamento dei pacchetti..."
apt update && apt upgrade -y

# Installazione di Samba
echo "Installazione di Samba..."
apt install -y samba

# Configurazione di Samba
echo "Configurazione di Samba..."
SAMBA_CONF="/etc/samba/smb.conf"

# Backup del file di configurazione originale
cp "$SAMBA_CONF" "${SAMBA_CONF}.bak"

# Modifica del file di configurazione
cat > "$SAMBA_CONF" <<EOF
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

[PublicShare]
comment = Cartella Pubica
path = /PUBSHARE
browseable = yes
guest ok = yes
writable = yes
guest only = yes
force create mode = 775
force directory mode = 775
EOF

# Creazione della directory condivisa per PublicShare
mkdir -p /PUBSHARE
chmod -R 0775 /PUBSHARE
chown -R nobody:nogroup /PUBSHARE

# Creazione del gruppo "shareGroup"
echo "Creazione del gruppo 'shareGroup'..."
if ! getent group shareGroup > /dev/null; then
    groupadd shareGroup
    echo "Gruppo 'shareGroup' creato con successo."
else
    echo "Gruppo 'shareGroup' già esistente."
fi

# Riavvio del servizio Samba
systemctl restart smbd
echo "Samba è stato installato e configurato con successo."

# Installazione di vsftpd
echo "Installazione del server FTP (vsftpd)..."
apt install -y vsftpd

# Configurazione di vsftpd
echo "Configurazione di vsftpd..."
VSFTPD_CONF="/etc/vsftpd.conf"

# Backup del file di configurazione originale
cp "$VSFTPD_CONF" "${VSFTPD_CONF}.bak"

# Configurazione di base per vsftpd
cat > "$VSFTPD_CONF" <<EOF
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
systemctl restart vsftpd
echo "Il server FTP è stato configurato con successo."

# Stato finale
echo "Installazione completata!"
echo "Samba è attivo con la condivisione 'PublicShare'."
echo "Il server FTP è attivo e pronto per l'uso."

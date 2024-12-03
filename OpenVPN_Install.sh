#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
   echo "Questo script deve essere eseguito come root. Usa sudo." 
   exit 1
fi

# Creazione della directory /root/OpenVPN/ se non esiste
OPENVPN_DIR="/root/OpenVPN"
if [[ ! -d "$OPENVPN_DIR" ]]; then
    echo "Creazione della directory $OPENVPN_DIR..."
    mkdir -p "$OPENVPN_DIR"
fi

# Spostarsi nella directory OpenVPN
cd "$OPENVPN_DIR"

# Scaricamento dello script OpenVPN
echo "Scaricamento dello script OpenVPN nella directory $OPENVPN_DIR..."
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh

# Impostazione dei permessi di esecuzione
echo "Impostazione dei permessi di esecuzione per lo script..."
chmod +x openvpn-install.sh

# Esecuzione dello script di installazione
echo "Avvio dello script di installazione OpenVPN..."
./openvpn-install.sh

# Fine script
echo "Il server OpenVPN è stato configurato. Segui le istruzioni dello script per completare la configurazione."

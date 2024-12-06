#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Usa sudo."
        exit 1
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    echo "Aggiornamento del sistema..."
    apt update && apt upgrade -y
}

# Funzione per installare i pacchetti richiesti
install_packages() {
    echo "Installazione dei pacchetti richiesti..."
    apt install -y python3 python3-pip python3-venv python3-dev build-essential \
        openjdk-17-jdk openjdk-17-jre htop screen nmap \
        transmission-cli transmission-daemon transmission-gtk iperf3 \
        zip unzip curl wget git
}

# Funzione per configurare Transmission con Web UI
configure_transmission() {
    echo "Configurazione di Transmission..."
    systemctl stop transmission-daemon

    # Creazione del file di configurazione
    cat > /etc/transmission-daemon/settings.json <<EOF
{
    "rpc-enabled": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-port": 9091,
    "rpc-username": "",
    "rpc-password": "",
    "rpc-whitelist": "*.*.*.*",
    "rpc-whitelist-enabled": false
}
EOF

    systemctl start transmission-daemon
    echo "Transmission Web UI è accessibile su http://<IP-del-server>:9091"
}

# Funzione per verificare i servizi configurati
check_services() {
    echo "Verifica dei servizi configurati..."
    systemctl status transmission-daemon | grep Active
}

# Funzione principale per eseguire tutte le operazioni
main() {
    check_root
    update_system
    install_packages
    configure_transmission
    check_services

    # Output finale
    echo "Setup completato!"
    echo "Transmission Web UI è accessibile su http://<IP-del-server>:9091"
}

# Esecuzione della funzione principale
main
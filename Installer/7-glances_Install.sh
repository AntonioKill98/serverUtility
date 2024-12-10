#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Usa sudo."
        exit 1
    fi
}

# Funzione per controllare e installare pip3
install_pip3_if_missing() {
    if ! command -v pip3 &> /dev/null; then
        echo "pip3 non è installato. Installazione in corso..."
        apt update && apt install -y python3-pip || { echo "Errore durante l'installazione di pip3."; exit 1; }
        echo "pip3 installato correttamente."
    fi
}

# Funzione per controllare se Glances è già installato
check_glances() {
    if pip3 show glances &> /dev/null; then
        echo "Glances è già installato."
        read -p "Vuoi rimuoverlo e reinstallarlo? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_glances
        else
            echo "Installazione annullata."
            exit 0
        fi
    fi
}

# Funzione per rimuovere Glances
remove_glances() {
    echo "Rimozione di Glances..."
    pip3 uninstall -y glances --break-system-packages || { echo "Errore durante la rimozione di Glances."; exit 1; }
    echo "Glances rimosso con successo."
}

# Funzione per installare Glances
install_glances() {
    echo "Installazione di Glances..."
    pip3 install --break-system-packages fastapi uvicorn || { echo "Errore durante l'installazione delle dipendenze di Glances."; exit 1; }
    pip3 install --break-system-packages glances || { echo "Errore durante l'installazione di Glances."; exit 1; }
    echo "Glances installato correttamente!"
}

# Aggiungere Glances -w in Autostart ad ogni riavvio
configure_glances_autostart() {
    echo "Configurazione di Glances per l'avvio automatico in modalità web server..."

    # Percorso del file di servizio
    SERVICE_FILE="/etc/systemd/system/glances.service"

    # Creazione del file di servizio
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Glances Web Server
After=network.target

[Service]
ExecStart=/usr/bin/glances -w
Restart=always
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

    # Ricarica i file di configurazione di systemd
    systemctl daemon-reload

    # Abilita e avvia il servizio
    systemctl enable glances
    systemctl start glances || { echo "Errore durante l'avvio del servizio Glances."; exit 1; }

    echo "Glances è stato configurato per avviarsi automaticamente all'accensione del sistema."
}

# Funzione principale
main() {
    check_root
    install_pip3_if_missing
    check_glances
    install_glances
    configure_glances_autostart
}

# Esecuzione dello script
main

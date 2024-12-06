#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Directory del progetto OpenSpeedTest
SPEEDTEST_DIR="/root/DockerContainers/OpenSpeedTest"
COMPOSE_FILE="$SPEEDTEST_DIR/docker-compose.yml"

# Funzione per verificare se una porta è in uso
check_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        echo "Controllo della porta $port..."
        if ss -tuln | grep -q ":$port "; then
            echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica i parametri del container."
            exit 1
        fi
    done
}

# Funzione per verificare se esiste già un container OpenSpeedTest
check_existing_container() {
    if docker ps -a --format "{{.Names}}" | grep -q "^openspeedtest\$"; then
        echo "Il container 'openspeedtest' esiste già."
        read -p "Vuoi rimuoverlo e ricrearlo? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            remove_existing_container
        else
            echo "Operazione annullata."
            exit 0
        fi
    fi
}

# Funzione per rimuovere un'installazione esistente
remove_existing_container() {
    echo "Rimozione del container esistente di OpenSpeedTest..."
    docker compose -f "$COMPOSE_FILE" down
    rm -rf "$SPEEDTEST_DIR"
    echo "Container e configurazione rimossi."
}

# Funzione per creare il file docker-compose.yml
create_compose_file() {
    echo "Creazione del file docker-compose.yml nella directory $SPEEDTEST_DIR..."
    mkdir -p "$SPEEDTEST_DIR"
    cat > "$COMPOSE_FILE" <<EOF
version: "3.8"

services:
  openspeedtest:
    image: openspeedtest/latest
    container_name: openspeedtest
    restart: unless-stopped
    ports:
      - "3200:3000"
      - "3201:3001"
EOF
}

# Funzione per avviare il container con Docker Compose
start_container() {
    echo "Avvio del container OpenSpeedTest con docker compose..."
    cd "$SPEEDTEST_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "OpenSpeedTest è stato avviato con successo!"
        echo "Puoi accedere a OpenSpeedTest su http://$(hostname -I | awk '{print $1}'):3200."
    else
        echo "Errore durante l'avvio di OpenSpeedTest."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    check_existing_container
    check_ports 3200 3201
    create_compose_file
    start_container
    echo "Configurazione completata."
}

# Esecuzione dello script
main

#!/bin/bash

# Verifica se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Usa sudo."
        exit 1
    fi
}

# Verifica se la porta è in uso
check_port() {
    local port="$1"
    if ss -tuln | grep -q ":$port "; then
        echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica il file compose."
        exit 1
    fi
}

# Funzione per rimuovere il container esistente
remove_existing_container() {
    local container_name="$1"
    local directory="$2"
    if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}\$"; then
        echo "Il container '${container_name}' esiste già."
        read -p "Vuoi rimuoverlo e ricrearlo? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo "Rimuovo il container '${container_name}'..."
            cd "$directory" && docker compose down
            rm -f "$directory/docker-compose.yml"
        else
            echo "Operazione annullata."
            exit 0
        fi
    fi
}

# Funzione per creare il file docker-compose.yml
create_docker_compose_file() {
    local directory="$1"
    local port="$2"
    echo "Creazione del file docker-compose.yml nella directory $directory..."
    cat > "$directory/docker-compose.yml" <<EOF
version: "3.8"

services:
  upsnap:
    image: seriousm4x/upsnap:latest
    container_name: upsnap
    restart: unless-stopped
    ports:
      - "$port:8090"
    volumes:
      - upsnap-data:/app/data

volumes:
  upsnap-data:
EOF
}

# Funzione per avviare il container
start_container() {
    local directory="$1"
    cd "$directory" || exit 1
    echo "Avvio di UpSnap..."
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "UpSnap è stato avviato con successo!"
        echo "Puoi accedere a UpSnap su http://<IP-del-server>:${PORT}"
    else
        echo "Errore durante l'avvio di UpSnap."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root

    # Configurazione
    PORT=3100
    UPS_DIR="/root/DockerContainers/UpSnap"
    CONTAINER_NAME="upsnap"

    echo "Verifica della presenza del container '${CONTAINER_NAME}'..."
    remove_existing_container "$CONTAINER_NAME" "$UPS_DIR"

    # Verifica della porta solo se il container non esiste
    if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}\$"; then
        echo "Controllo della porta $PORT..."
        check_port "$PORT"
    fi

    # Creazione della directory se non esiste
    if [[ ! -d "$UPS_DIR" ]]; then
        echo "Creazione della directory $UPS_DIR..."
        mkdir -p "$UPS_DIR"
    fi

    # Creazione del file docker-compose.yml
    create_docker_compose_file "$UPS_DIR" "$PORT"

    # Avvio del container
    start_container "$UPS_DIR"
}

# Esecuzione dello script
main


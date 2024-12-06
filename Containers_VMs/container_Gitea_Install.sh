#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Imposta la directory del progetto Docker
GITEA_DIR="/root/DockerContainers/Gitea"
COMPOSE_FILE="$GITEA_DIR/docker-compose.yml"

# Funzione per verificare se esiste già un'installazione di Gitea
check_existing_installation() {
    if [[ -d "$GITEA_DIR" ]]; then
        echo "È stata rilevata un'installazione esistente di Gitea."
        read -p "Vuoi rimuovere l'installazione esistente e reinstallare tutto? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            remove_existing_installation
        else
            echo "Uscita dallo script senza apportare modifiche."
            exit 0
        fi
    fi
}

# Funzione per rimuovere l'installazione esistente
remove_existing_installation() {
    echo "Rimozione dell'installazione esistente di Gitea..."
    docker compose -f "$COMPOSE_FILE" down
    rm -rf "$GITEA_DIR"
    echo "Installazione esistente rimossa."
}

# Funzione per verificare se le porte richieste sono disponibili
check_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica il file compose."
            exit 1
        fi
    done
}

# Funzione per creare il file docker-compose.yml
create_compose_file() {
    echo "Creazione del file docker-compose.yml nella directory $GITEA_DIR..."
    mkdir -p "$GITEA_DIR"
    cat > "$COMPOSE_FILE" <<EOF
version: "3"

networks:
    gitea:
        external: false

services:
  server:
    image: gitea/gitea
    container_name: gitea
    environment:
        - USER_UID=1000
        - USER_GID=100
        - GITEA__database__DB_TYPE=mysql
        - GITEA__database__HOST=db:3306
        - GITEA__database__NAME=gitea
        - GITEA__database__USER=gitea
        - GITEA__database__PASSWD=gitea
    restart: always
    networks:
        - gitea
    volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
    ports:
        - "3000:3000"
        - "2022:22"
    depends_on:
        - db

  db:
    image: mysql
    restart: always
    environment:
        - MYSQL_ROOT_PASSWORD=gitea
        - MYSQL_USER=gitea
        - MYSQL_PASSWORD=gitea
        - MYSQL_DATABASE=gitea
    networks:
        - gitea
    volumes:
        - ./mysql:/var/lib/mysql
EOF
}

# Funzione per avviare i container Docker
start_containers() {
    echo "Avvio dei container con docker compose..."
    cd "$GITEA_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Container Gitea avviati con successo!"
        echo "Gitea è disponibile all'indirizzo: http://$(hostname -I | awk '{print $1}'):3000"
    else
        echo "Errore durante l'avvio dei container."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    check_existing_installation
    check_ports 3000 2022
    create_compose_file
    start_containers
    echo "Configurazione completata."
}

# Esecuzione dello script
main

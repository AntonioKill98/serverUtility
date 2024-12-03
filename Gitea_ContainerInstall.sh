#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
   echo "Questo script deve essere eseguito come root. Usa sudo." 
   exit 1
fi

# Imposta la directory del progetto Docker
GITEA_DIR="/root/DockerContainers/Gitea"
COMPOSE_FILE="$GITEA_DIR/docker-compose.yml"

# Verifica se le porte richieste sono disponibili
check_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica il file docker-compose."
            exit 1
        fi
    done
}

# Controlla le porte lato host
echo "Controllo delle porte lato host..."
check_ports 3001 2022

# Crea la directory per Gitea se non esiste
if [[ ! -d "$GITEA_DIR" ]]; then
    echo "Creazione della directory $GITEA_DIR..."
    mkdir -p "$GITEA_DIR"
fi

# Genera il file docker-compose.yml
echo "Generazione del file docker-compose.yml nella directory $GITEA_DIR..."
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
        - USER_UID=1000 # Enter the UID found from previous command output
        - USER_GID=100 # Enter the GID found from previous command output
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

# Spostarsi nella directory del compose
cd "$GITEA_DIR"

# Avviare i container con docker-compose
echo "Avvio dei container con docker-compose..."
docker-compose up -d

# Controllo dello stato dei container
if [[ $? -eq 0 ]]; then
    echo "Container Gitea avviati con successo!"
else
    echo "Errore durante l'avvio dei container."
    exit 1
fi

# Fine script
echo "Configurazione completata."

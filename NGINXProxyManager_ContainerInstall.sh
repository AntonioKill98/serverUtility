#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Imposta la directory del progetto Docker
NGINX_DIR="/root/DockerContainers/NGINXProxyManager"
COMPOSE_FILE="$NGINX_DIR/docker-compose.yml"

# Funzione per controllare se una porta è in uso
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
check_ports 80 443 81

# Crea la directory per Nginx Proxy Manager se non esiste
if [[ ! -d "$NGINX_DIR" ]]; then
    echo "Creazione della directory $NGINX_DIR..."
    mkdir -p "$NGINX_DIR"
fi

# Genera il file docker-compose.yml
echo "Generazione del file docker-compose.yml nella directory $NGINX_DIR..."
cat > "$COMPOSE_FILE" <<EOF
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'    # Public HTTP Port
      - '443:443'  # Public HTTPS Port
      - '81:81'    # Admin Web Port
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF

# Spostarsi nella directory del compose
cd "$NGINX_DIR"

# Avviare i container con docker-compose
echo "Avvio dei container con docker-compose..."
docker-compose up -d

# Controllo dello stato dei container
if [[ $? -eq 0 ]]; then
    echo "Nginx Proxy Manager avviato con successo!"
    echo "Puoi accedere alla dashboard su http://<IP-del-server>:81."
else
    echo "Errore durante l'avvio di Nginx Proxy Manager."
    exit 1
fi

# Fine script
echo "Configurazione completata."

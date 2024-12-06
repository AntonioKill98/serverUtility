#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Directory del progetto Nginx Proxy Manager
NGINX_DIR="/root/DockerContainers/NGINXProxyManager"
DEFAULT_PAGE_DIR="$NGINX_DIR/httpDefaultPage"
COMPOSE_FILE="$NGINX_DIR/docker-compose.yml"

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

# Funzione per verificare se esiste già un container Nginx Proxy Manager
check_existing_container() {
    if docker ps -a --format "{{.Names}}" | grep -q "^nginxproxymanager\$"; then
        echo "Il container 'nginxproxymanager' esiste già."
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
    echo "Rimozione del container esistente di Nginx Proxy Manager..."
    docker compose -f "$COMPOSE_FILE" down
    rm -rf "$NGINX_DIR"
    echo "Container e configurazione rimossi."
}

# Funzione per creare il file docker-compose.yml
create_compose_file() {
    echo "Creazione del file docker-compose.yml nella directory $NGINX_DIR..."
    mkdir -p "$NGINX_DIR"
    cat > "$COMPOSE_FILE" <<EOF
version: '3.8'

services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginxproxymanager
    restart: unless-stopped
    ports:
      - '80:80'    # Public HTTP Port
      - '443:443'  # Public HTTPS Port
      - '81:81'    # Admin Web Port
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
      - ./httpDefaultPage:/var/www/html
EOF
}

# Funzione per creare il file HTML di default
create_default_page() {
    echo "Creazione della pagina HTML di default..."
    mkdir -p "$DEFAULT_PAGE_DIR"
    cat > "$DEFAULT_PAGE_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Installazione NGINX Riuscita</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            background-color: #f4f4f9;
            margin: 0;
            padding: 0;
        }
        h1 {
            color: #4CAF50;
            margin-top: 20%;
        }
        p {
            color: #555;
            font-size: 1.2em;
        }
        footer {
            margin-top: 20px;
            font-size: 0.9em;
            color: #888;
        }
    </style>
</head>
<body>
    <h1>Installazione NGINX Riuscita</h1>
    <p>Puoi modificare questa pagina modificando il file in:</p>
    <p><code>$DEFAULT_PAGE_DIR/index.html</code></p>
    <footer>NGINX Proxy Manager</footer>
</body>
</html>
EOF
}

# Funzione per avviare il container con Docker Compose
start_container() {
    echo "Avvio del container Nginx Proxy Manager con docker compose..."
    cd "$NGINX_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Nginx Proxy Manager avviato con successo!"
        echo "Puoi accedere alla dashboard su http://$(hostname -I | awk '{print $1}'):81."
        echo "La pagina di default HTTP è disponibile su http://$(hostname -I | awk '{print $1}')/."
    else
        echo "Errore durante l'avvio di Nginx Proxy Manager."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    check_existing_container
    check_ports 80 443 81
    create_compose_file
    create_default_page
    start_container
    echo "Configurazione completata."
}

# Esecuzione dello script
main

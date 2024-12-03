#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Porta predefinita per UpSnap
PORT=3100

# Verifica se la porta è in uso
check_port() {
    if netstat -tuln | grep -q ":$PORT "; then
        echo "Errore: La porta $PORT è già in uso. Rilascia la porta o modifica il file compose."
        exit 1
    fi
}

echo "Controllo della porta $PORT..."
check_port

# Directory per il container
UPS_DIR="/root/DockerContainers/UpSnap"

# Creazione della directory se non esiste
if [[ ! -d "$UPS_DIR" ]]; then
    echo "Creazione della directory $UPS_DIR..."
    mkdir -p "$UPS_DIR"
fi

# Creazione del file docker-compose.yml
cat > "$UPS_DIR/docker-compose.yml" <<EOF
version: "3.8"

services:
  upsnap:
    image: seriousm4x/upsnap:latest
    container_name: upsnap
    restart: unless-stopped
    ports:
      - "$PORT:3000"
    volumes:
      - upsnap-data:/app/data

volumes:
  upsnap-data:
EOF

# Spostarsi nella directory del container
cd "$UPS_DIR"

# Avvio del container con Docker Compose
echo "Avvio di UpSnap..."
docker-compose up -d

# Verifica dello stato del container
if [[ $? -eq 0 ]]; then
    echo "UpSnap è stato avviato con successo!"
    echo "Puoi accedere a UpSnap su http://<IP-del-server>:$PORT"
else
    echo "Errore durante l'avvio di UpSnap."
    exit 1
fi

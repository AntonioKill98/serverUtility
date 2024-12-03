#!/bin/bash

# Verifica esecuzione come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Directory per Immich
IMMICH_DIR="/root/DockerContainers/ImmichApp"

# Crea la directory se non esiste
if [[ ! -d "$IMMICH_DIR" ]]; then
    mkdir -p "$IMMICH_DIR"
fi

# Sposta nella directory di Immich
cd "$IMMICH_DIR"

# Scarica il file docker-compose.yml
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

# Chiede il percorso della libreria foto
while true; do
    read -p "Inserisci il percorso assoluto per la libreria foto: " PHOTO_LIBRARY_PATH
    if [[ -d "$PHOTO_LIBRARY_PATH" ]]; then
        break
    else
        echo "Errore: Il percorso $PHOTO_LIBRARY_PATH non è valido. Riprova."
    fi
done

# Genera una password casuale per il database
DB_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)

# Crea il file .env con i parametri necessari
cat > example.env <<EOF
UPLOAD_LOCATION=$PHOTO_LIBRARY_PATH
DB_DATA_LOCATION=./postgres
TZ=Europe/Rome
IMMICH_VERSION=release
DB_PASSWORD=$DB_PASSWORD
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
EOF

# Avvia Immich con docker-compose
docker-compose up -d

# Controlla lo stato del container
if [[ $? -eq 0 ]]; then
    echo "Immich avviato con successo!"
    echo "Libreria foto: $PHOTO_LIBRARY_PATH"
    echo "Password database: $DB_PASSWORD"
else
    echo "Errore durante l'avvio di Immich."
    exit 1
fi

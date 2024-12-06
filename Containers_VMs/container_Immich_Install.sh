#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Directory per Immich
IMMICH_DIR="/root/DockerContainers/ImmichApp"
COMPOSE_FILE="$IMMICH_DIR/docker-compose.yml"
ENV_FILE="$IMMICH_DIR/.env"

# Variabili globali
PHOTO_LIBRARY_PATH=""
DB_PASSWORD=""

# Funzione per verificare se esiste già un'installazione di Immich
check_existing_installation() {
    if [[ -d "$IMMICH_DIR" ]]; then
        echo "È stata rilevata un'installazione esistente di Immich."
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
    echo "Rimozione dell'installazione esistente di Immich..."
    docker compose -f "$COMPOSE_FILE" down
    rm -rf "$IMMICH_DIR"
    echo "Installazione esistente rimossa."
}

# Funzione per verificare se la porta richiesta è disponibile
check_port() {
    local port="$1"
    echo "Verifica che la porta $port sia disponibile..."
    if ss -tuln | grep -q ":$port "; then
        echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica il file compose."
        exit 1
    fi
}

# Funzione per configurare Immich
configure_immich() {
    echo "Configurazione di Immich nella directory $IMMICH_DIR..."
    mkdir -p "$IMMICH_DIR"
    cd "$IMMICH_DIR"

    # Scarica il file docker-compose.yml
    echo "Scaricamento del file docker-compose.yml..."
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

    # Crea il file .env
    echo "Creazione del file .env con i parametri richiesti..."
    cat > "$ENV_FILE" <<EOF
UPLOAD_LOCATION=$PHOTO_LIBRARY_PATH
DB_DATA_LOCATION=./postgres
TZ=Europe/Rome
IMMICH_VERSION=release
DB_PASSWORD=$DB_PASSWORD
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
EOF

    # Imposta i permessi corretti per il file .env
    chmod 600 "$ENV_FILE"

    echo "Configurazione completata."
    echo "Password generata per il database: $DB_PASSWORD"
}

# Funzione per avviare Immich
start_immich() {
    echo "Avvio di Immich con docker compose..."
    cd "$IMMICH_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Immich avviato con successo!"
        echo "Indirizzo Immich: http://$(hostname -I | awk '{print $1}'):2283"
        echo "Libreria foto: $PHOTO_LIBRARY_PATH"
        echo "Password database: $DB_PASSWORD"
    else
        echo "Errore durante l'avvio di Immich."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    check_existing_installation
    check_port 2283
    configure_immich
    start_immich
}

# Esecuzione dello script
main

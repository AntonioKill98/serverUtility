#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Directory del progetto Portainer
PORTAINER_DIR="/root/DockerContainers/Portainer"
COMPOSE_FILE="$PORTAINER_DIR/docker-compose.yml"

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

# Funzione per verificare se esiste già un container Portainer
check_existing_container() {
    if docker ps -a --format "{{.Names}}" | grep -q "^portainer\$"; then
        echo "Il container 'portainer' esiste già."
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
    echo "Rimozione del container esistente di Portainer..."
    docker compose -f "$COMPOSE_FILE" down
    docker volume rm -f portainer_data
    rm -rf "$PORTAINER_DIR"
    echo "Container e volume rimossi."
}

# Funzione per creare il file docker-compose.yml
create_compose_file() {
    echo "Creazione del file docker-compose.yml nella directory $PORTAINER_DIR..."
    mkdir -p "$PORTAINER_DIR"
    cat > "$COMPOSE_FILE" <<EOF
version: "3.8"

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "8000:8000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
EOF
}

# Funzione per avviare il container con Docker Compose
start_container() {
    echo "Avvio del container Portainer con docker compose..."
    cd "$PORTAINER_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Portainer è stato avviato con successo!"
        echo "Puoi accedere a Portainer su https://$(hostname -I | awk '{print $1}'):9443."
    else
        echo "Errore durante l'avvio di Portainer."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    check_existing_container
    check_ports 8000 9443
    create_compose_file
    start_container
    echo "Configurazione completata."
}

# Esecuzione dello script
main

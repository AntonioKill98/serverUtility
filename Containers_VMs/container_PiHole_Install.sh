#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Directory del progetto Pi-hole
PIHOLE_DIR="/root/DockerContainers/piHole"
COMPOSE_FILE="$PIHOLE_DIR/docker-compose.yml"

# Variabile per la password
WEBPASSWORD=""

# Funzione per generare una password casuale
generate_password() {
    WEBPASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
    echo "Password generata per l'interfaccia web di Pi-hole: $WEBPASSWORD"
}

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

# Funzione per verificare se esiste già un container Pi-hole
check_existing_container() {
    if docker ps -a --format "{{.Names}}" | grep -q "^pihole\$"; then
        echo "Il container 'pihole' esiste già."
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
    echo "Rimozione del container esistente di Pi-hole..."
    docker compose -f "$COMPOSE_FILE" down
    rm -rf "$PIHOLE_DIR"
    echo "Container e configurazione rimossi."
}

# Funzione per creare il file docker-compose.yml
create_compose_file() {
    echo "Creazione del file docker-compose.yml nella directory $PIHOLE_DIR..."
    mkdir -p "$PIHOLE_DIR"
    cat > "$COMPOSE_FILE" <<EOF
version: "3"

# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      - "8080:80/tcp" # Modified to avoid conflict with Nginx
    environment:
      TZ: 'Europe/Rome'
      WEBPASSWORD: '$WEBPASSWORD'
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
    restart: unless-stopped
EOF
}

# Funzione per avviare il container con Docker Compose
start_container() {
    echo "Avvio del container Pi-hole con docker compose..."
    cd "$PIHOLE_DIR"
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Pi-hole è stato avviato con successo!"
        echo "Puoi accedere all'interfaccia web di Pi-hole su http://$(hostname -I | awk '{print $1}'):8080/admin."
        echo "La password per l'interfaccia web di Pi-hole è: $WEBPASSWORD"
    else
        echo "Errore durante l'avvio di Pi-hole."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    generate_password
    check_existing_container
    check_ports 53 8080 67
    create_compose_file
    start_container
    echo "Configurazione completata."
}

# Esecuzione dello script
main

#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Chiede all'utente di fornire una password
read -sp "Inserisci la password per l'interfaccia web di Pi-hole: " WEBPASSWORD
echo

# Verifica se la password è vuota
if [[ -z "$WEBPASSWORD" ]]; then
    echo "Errore: Devi inserire una password. Riprova."
    exit 1
fi

# Imposta la directory del progetto Docker
PIHOLE_DIR="/root/DockerContainers/piHole"
COMPOSE_FILE="$PIHOLE_DIR/docker-compose.yml"

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
check_ports 53 8080 67

# Crea la directory per Pi-hole se non esiste
if [[ ! -d "$PIHOLE_DIR" ]]; then
    echo "Creazione della directory $PIHOLE_DIR..."
    mkdir -p "$PIHOLE_DIR"
fi

# Genera il file docker-compose.yml
echo "Generazione del file docker-compose.yml nella directory $PIHOLE_DIR..."
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

# Spostarsi nella directory del compose
cd "$PIHOLE_DIR"

# Avviare i container con docker-compose
echo "Avvio dei container con docker-compose..."
docker-compose up -d

# Controllo dello stato del container
if [[ $? -eq 0 ]]; then
    echo "Pi-hole è stato avviato con successo!"
    echo "Puoi accedere all'interfaccia web di Pi-hole su http://<IP-del-server>:8080."
else
    echo "Errore durante l'avvio di Pi-hole."
    exit 1
fi

# Fine script
echo "Configurazione completata."

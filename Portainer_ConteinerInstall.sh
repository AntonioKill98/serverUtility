#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Funzione per controllare se una porta è in uso
check_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica i parametri del container."
            exit 1
        fi
    done
}

# Controlla le porte lato host
echo "Controllo delle porte lato host..."
check_ports 8000 9443

# Crea il volume per Portainer
echo "Creazione del volume Docker per Portainer..."
docker volume create portainer_data

# Esegue il container di Portainer
echo "Avvio del container Portainer..."
docker run -d -p 8000:8000 -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:2.21.4

# Controllo dello stato del container
if [[ $? -eq 0 ]]; then
    echo "Portainer è stato avviato con successo!"
    echo "Puoi accedere a Portainer su https://<IP-del-server>:9443."
else
    echo "Errore durante l'avvio di Portainer."
    exit 1
fi

# Fine script
echo "Configurazione completata."

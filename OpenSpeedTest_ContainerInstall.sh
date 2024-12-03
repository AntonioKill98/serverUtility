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
            echo "Errore: La porta $port è già in uso. Rilascia la porta o modifica il comando."
            exit 1
        fi
    done
}

# Controlla le porte lato host
echo "Controllo delle porte lato host..."
check_ports 3100 3101

# Creazione e avvio del container OpenSpeedTest
echo "Avvio del container OpenSpeedTest con porte modificate..."
docker run --restart=unless-stopped --name openspeedtest -d \
    -p 3100:3000 \
    -p 3101:3001 \
    openspeedtest/latest

# Controllo dello stato del container
if [[ $? -eq 0 ]]; then
    echo "OpenSpeedTest è stato avviato con successo!"
    echo "Puoi accedere a OpenSpeedTest su http://<IP-del-server>:3100."
else
    echo "Errore durante l'avvio di OpenSpeedTest."
    exit 1
fi

# Fine script
echo "Configurazione completata."

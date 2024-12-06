#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    echo "Aggiornamento dei pacchetti di sistema..."
    apt-get update && apt-get upgrade -y
}

# Funzione per installare le dipendenze necessarie
install_dependencies() {
    echo "Installazione delle dipendenze di base..."
    apt-get install -y ca-certificates curl gnupg lsb-release
}

# Funzione per aggiungere il repository ufficiale di Docker
setup_docker_repository() {
    echo "Configurazione del repository ufficiale di Docker..."
    
    # Creazione della directory per le chiavi APT
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Aggiunta del repository a APT sources
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
}

# Funzione per installare Docker
install_docker() {
    echo "Installazione di Docker e dei relativi strumenti..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
}

# Funzione per installare l'ultima versione di Docker Compose
install_docker_compose() {
    echo "Installazione dell'ultima versione di Docker Compose..."
    
    # Recupera l'ultima versione di Docker Compose
    local latest_compose_version
    latest_compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

    # Scarica Docker Compose
    curl -SL "https://github.com/docker/compose/releases/download/${latest_compose_version}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose

    # Rendi eseguibile il binario
    chmod +x /usr/local/bin/docker-compose

    # Verifica l'installazione
    if docker-compose --version &> /dev/null; then
        echo "Docker Compose è stato installato correttamente:"
        docker-compose --version
    else
        echo "Errore: Docker Compose non è stato installato correttamente."
        exit 1
    fi
}

# Funzione per verificare l'installazione di Docker
verify_docker_installation() {
    echo "Verifica dell'installazione di Docker..."
    if docker --version &> /dev/null; then
        echo "Docker è stato installato correttamente:"
        docker --version
    else
        echo "Errore: Docker non è stato installato correttamente."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    update_system
    install_dependencies
    setup_docker_repository
    install_docker
    verify_docker_installation
    install_docker_compose
    echo "Installazione di Docker e Docker Compose completata con successo!"
}

# Esecuzione dello script
main

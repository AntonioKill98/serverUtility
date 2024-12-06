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
    apt-get install -y wget gnupg lsb-release apt-transport-https
}

# Funzione per configurare il repository ufficiale di VirtualBox
setup_virtualbox_repository() {
    echo "Configurazione del repository ufficiale di VirtualBox..."
    
    # Scarica e configura la chiave GPG
    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

    # Determina la distribuzione corrente
    local dist=$(lsb_release -cs)

    # Aggiungi il repository a APT sources
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $dist contrib" | tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
}

# Funzione per rilevare la versione più recente di VirtualBox
get_latest_virtualbox_version() {
    echo "Rilevamento della versione più recente di VirtualBox..." >&2
    local full_version
    full_version=$(wget -qO- https://download.virtualbox.org/virtualbox/LATEST.TXT)
    if [[ -z "$full_version" ]]; then
        echo "Errore nel rilevamento della versione più recente di VirtualBox." >&2
        exit 1
    fi

    # Estrai la macroversione (es. da 7.1.4 otteniamo 7.1)
    local macro_version
    macro_version=$(echo "$full_version" | cut -d. -f1,2)

    # Restituisci solo i dati necessari
    echo "$full_version $macro_version"
}

# Funzione per installare VirtualBox
install_virtualbox() {
    local macro_version="$1"

    echo "Installazione di VirtualBox versione $macro_version..."
    apt-get update
    apt-get install -y "virtualbox-$macro_version"
}

# Funzione per installare l'Extension Pack
install_extension_pack() {
    local full_version="$1"

    echo "Installazione dell'Extension Pack per VirtualBox versione $full_version..."
    local extension_pack_url="https://download.virtualbox.org/virtualbox/${full_version}/Oracle_VirtualBox_Extension_Pack-${full_version}.vbox-extpack"
    local extension_pack_file="/tmp/Oracle_VirtualBox_Extension_Pack-${full_version}.vbox-extpack"

    # Scarica l'Extension Pack
    echo "Scaricamento dell'Extension Pack da $extension_pack_url..."
    wget -q --show-progress -O "$extension_pack_file" "$extension_pack_url"

    # Verifica che il file sia valido
    if [[ ! -f "$extension_pack_file" || $(stat -c%s "$extension_pack_file") -lt 100000 ]]; then
        echo "Errore: File dell'Extension Pack corrotto o incompleto."
        rm -f "$extension_pack_file"
        exit 1
    fi

    # Accetta automaticamente la licenza simulando "y"
    echo "Accettazione della licenza e installazione dell'Extension Pack..."
    if echo "y" | vboxmanage extpack install --replace "$extension_pack_file"; then
        echo "Extension Pack installato con successo."
    else
        echo "Errore durante l'installazione dell'Extension Pack."
        rm -f "$extension_pack_file"
        exit 1
    fi

    # Rimuovi il file temporaneo
    rm -f "$extension_pack_file"
}

# Funzione per verificare l'installazione di VirtualBox
verify_virtualbox_installation() {
    echo "Verifica dell'installazione di VirtualBox..."
    if vboxmanage --version &> /dev/null; then
        echo "VirtualBox è stato installato correttamente:"
        vboxmanage --version
    else
        echo "Errore: VirtualBox non è stato installato correttamente."
        exit 1
    fi
}

# Funzione principale
main() {
    check_root
    update_system
    install_dependencies
    setup_virtualbox_repository

    # Recupera la versione più recente
    local full_version
    local macro_version
    read -r full_version macro_version < <(get_latest_virtualbox_version)

    if [[ -z "$macro_version" ]]; then
        echo "Errore nel rilevamento della macroversione di VirtualBox."
        exit 1
    fi

    # Installa VirtualBox e l'Extension Pack
    install_virtualbox "$macro_version"
    verify_virtualbox_installation
    install_extension_pack "$full_version"

    echo "Installazione di VirtualBox e dell'Extension Pack completata con successo!"
}

# Esecuzione dello script
main

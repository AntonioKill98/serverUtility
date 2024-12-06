#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per creare la directory OpenVPN
setup_openvpn_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Creazione della directory $dir..."
        mkdir -p "$dir"
    else
        echo "La directory $dir esiste già."
    fi
}

# Funzione per scaricare lo script OpenVPN
download_openvpn_script() {
    local dir="$1"
    local script_url="https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh"
    local script_path="$dir/openvpn-install.sh"

    echo "Scaricamento dello script OpenVPN nella directory $dir..."
    curl -fsSL -o "$script_path" "$script_url"

    if [[ -f "$script_path" ]]; then
        echo "Script OpenVPN scaricato correttamente in $script_path."
        chmod +x "$script_path"
    else
        echo "Errore: impossibile scaricare lo script OpenVPN."
        exit 1
    fi
}

# Funzione per verificare e avviare lo script OpenVPN
run_openvpn_script() {
    local script_path="$1"
    if [[ -f "$script_path" ]]; then
        echo "Avvio dello script di installazione OpenVPN..."
        bash "$script_path"
    else
        echo "Errore: lo script $script_path non esiste. Verifica il download."
        exit 1
    fi
}

# Funzione principale
main() {
    local openvpn_dir="/root/OpenVPN"

    check_root
    setup_openvpn_directory "$openvpn_dir"
    download_openvpn_script "$openvpn_dir"
    run_openvpn_script "$openvpn_dir/openvpn-install.sh"

    echo "Lo script di installazione OpenVPN è stato eseguito correttamente."
    echo "Segui le istruzioni dello script per completare la configurazione del server OpenVPN."
}

# Esecuzione dello script
main

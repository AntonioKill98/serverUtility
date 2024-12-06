#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Usa sudo."
        exit 1
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    echo "Aggiornamento del sistema..."
    apt update && apt upgrade -y
}

# Funzione per installare i pacchetti grafici
install_graphics_packages() {
    echo "Installazione dei pacchetti grafici..."
    apt install -y xorg pekwm xterm tint2 lxterminal firefox-esr gparted \
        x11-apps xinput xbacklight xbindkeys x11-utils pcmanfm geany
}

# Funzione principale per eseguire tutte le operazioni
main() {
    check_root
    update_system
    install_graphics_packages

    # Output finale
    echo "Installazione grafica completata!"
    echo "Esegui 'startx' per avviare PekWM. Poi esegui lo script di configurazione."
}

# Esecuzione della funzione principale
main

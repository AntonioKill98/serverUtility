#!/bin/bash

# Funzione per configurare PekWM
configure_pekwm() {
    echo "Configurazione di PekWM..."

    PEKWM_CONFIG_DIR="$HOME/.pekwm"

    # Configurazione per avviare Tint2
    cat >> "$PEKWM_CONFIG_DIR/start" <<EOF
#!/bin/bash
setxkbmap it &
tint2 &
EOF
    chmod +x "$PEKWM_CONFIG_DIR/start"

    # Aggiunta del menu personalizzato nel file esistente
    MENU_FILE="$PEKWM_CONFIG_DIR/menu"
    if [[ -f "$MENU_FILE" ]]; then
        sed -i '/Submenu = "Pekwm" {/,/Separator {}/ { 
        /Separator {}/a \
        Submenu = "My Apps" { \
            Entry = "Web Browser" { Actions = "Exec firefox-esr" } \
            Entry = "File Manager" { Actions = "Exec pcmanfm" } \
            Entry = "Text Editor" { Actions = "Exec geany" } \
            Entry = "HTop" { Actions = "Exec uxterm -e htop" } \
            Entry = "Transmission" { Actions = "Exec transmission-gtk" } \
            Entry = "Glances" { Actions = "Exec uxterm -e glances" } \
            Entry = "GParted" { Actions = "Exec gparted" } \
        } \
        Separator {}
        }' "$MENU_FILE"
    else
        echo "File menu non trovato. Assicurati di aver avviato PekWM almeno una volta con startx."
    fi
}

# Funzione principale per eseguire tutte le operazioni
main() {
    configure_pekwm

    # Output finale
    echo "Configurazione di PekWM completata!"
    echo "Riavvia PekWM per applicare le modifiche."
}

# Esecuzione della funzione principale
main

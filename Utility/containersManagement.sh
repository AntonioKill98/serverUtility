#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per verificare se Docker è installato
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Errore: Docker non è installato. Installa Docker prima di eseguire questo script."
        exit 1
    fi
}

# Funzione per elencare tutti i container Docker con il loro stato
list_containers() {
    echo "Elenco dei container Docker:"
    local containers=()
    local index=1
    while IFS= read -r line; do
        CONTAINER_NAME=$(echo "$line" | awk '{print $1}')
        STATE=$(echo "$line" | awk '{print $2}')
        if [[ "$STATE" == "running" ]]; then
            echo -e "  [$index] $CONTAINER_NAME \033[0;32m(AVVIATO)\033[0m"
        else
            echo -e "  [$index] $CONTAINER_NAME \033[0;31m(FERMO)\033[0m"
        fi
        containers+=("$CONTAINER_NAME")
        ((index++))
    done < <(docker ps -a --format '{{.Names}} {{.State}}')
    CONTAINER_LIST=("${containers[@]}")
}

# Funzione per selezionare un container
select_container() {
    read -p "Seleziona il numero del container: " choice
    if [[ -n "${CONTAINER_LIST[$((choice-1))]}" ]]; then
        SELECTED_CONTAINER="${CONTAINER_LIST[$((choice-1))]}"
        echo "Hai selezionato: $SELECTED_CONTAINER"
    else
        echo "Selezione non valida. Uscita."
        exit 1
    fi
}

# Funzione per avviare un container
start_container() {
    docker start "$SELECTED_CONTAINER"
    echo "Container '$SELECTED_CONTAINER' avviato con successo."
}

# Funzione per fermare un container
stop_container() {
    docker stop "$SELECTED_CONTAINER"
    echo "Container '$SELECTED_CONTAINER' fermato."
}

# Funzione per ottenere informazioni su un container
get_container_info() {
    docker inspect "$SELECTED_CONTAINER"
}

# Funzione per mostrare il menu principale
show_menu() {
    echo "Seleziona un'azione:"
    echo "  [1] Avviare un container"
    echo "  [2] Fermare un container"
    echo "  [3] Ottenere informazioni su un container"
    echo "  [4] Uscire"
    read -p "Scelta: " action
    case $action in
        1)
            echo "Hai scelto di avviare un container."
            list_containers
            select_container
            start_container
            ;;
        2)
            echo "Hai scelto di fermare un container."
            list_containers
            select_container
            stop_container
            ;;
        3)
            echo "Hai scelto di ottenere informazioni su un container."
            list_containers
            select_container
            get_container_info
            ;;
        4)
            echo "Uscita dallo script."
            exit 0
            ;;
        *)
            echo "Scelta non valida. Riprova."
            ;;
    esac
}

# Funzione principale
main() {
    check_root
    check_docker
    while true; do
        show_menu
    done
}

# Dichiarazione array globale per i container
declare -a CONTAINER_LIST
SELECTED_CONTAINER=""

# Esecuzione dello script
main

#!/bin/bash

# Funzione per verificare se lo script è eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per controllare se VirtualBox è installato
check_virtualbox() {
    if ! command -v VBoxManage &> /dev/null; then
        echo "Errore: VirtualBox non è installato. Installa VirtualBox prima di eseguire questo script."
        exit 1
    fi
}

# Funzione per elencare tutte le VM con il loro stato
list_vms() {
    echo "Elenco delle Virtual Machines:"
    VMS=$(VBoxManage list vms | awk -F'"' '{print $2}')
    ACTIVE_VMS=$(VBoxManage list runningvms | awk -F'"' '{print $2}')

    local index=1
    for vm in $VMS; do
        if echo "$ACTIVE_VMS" | grep -q "^$vm$"; then
            echo -e "  [$index] $vm \033[0;32m(ATTIVA)\033[0m"
        else
            echo -e "  [$index] $vm \033[0;31m(INATTIVA)\033[0m"
        fi
        VM_LIST[$index]="$vm"
        ((index++))
    done
}

# Funzione per selezionare una VM
select_vm() {
    read -p "Seleziona il numero della VM: " choice
    if [[ -n "${VM_LIST[$choice]}" ]]; then
        SELECTED_VM="${VM_LIST[$choice]}"
        echo "Hai selezionato: $SELECTED_VM"
    else
        echo "Selezione non valida. Uscita."
        exit 1
    fi
}

# Funzione per avviare una VM
start_vm() {
    VBoxManage startvm "$SELECTED_VM" --type headless
    echo "VM '$SELECTED_VM' avviata con successo."
}

# Funzione per fermare una VM
stop_vm() {
    VBoxManage controlvm "$SELECTED_VM" acpipowerbutton
    echo "VM '$SELECTED_VM' fermata."
}

# Funzione per ottenere informazioni su una VM
get_vm_info() {
    VBoxManage showvminfo "$SELECTED_VM"
}

# Funzione per mostrare il menu principale
show_menu() {
    echo "Seleziona un'azione:"
    echo "  [1] Avviare una VM"
    echo "  [2] Fermare una VM"
    echo "  [3] Ottenere informazioni su una VM"
    echo "  [4] Uscire"
    read -p "Scelta: " action
    case $action in
        1)
            echo "Hai scelto di avviare una VM."
            list_vms
            select_vm
            start_vm
            ;;
        2)
            echo "Hai scelto di fermare una VM."
            list_vms
            select_vm
            stop_vm
            ;;
        3)
            echo "Hai scelto di ottenere informazioni su una VM."
            list_vms
            select_vm
            get_vm_info
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
    check_virtualbox
    while true; do
        show_menu
    done
}

# Dichiarazione array globale per le VM
declare -A VM_LIST
SELECTED_VM=""

# Esecuzione dello script
main

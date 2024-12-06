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

# Funzione per verificare se esiste già una VM
check_existing_vm() {
    if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
        echo "La VM '${VM_NAME}' esiste già."
        read -p "Vuoi rimuoverla e ricrearla? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            remove_existing_vm
        else
            echo "Operazione annullata."
            exit 0
        fi
    fi
}

# Funzione per rimuovere una VM esistente
remove_existing_vm() {
    echo "Rimozione della VM esistente '${VM_NAME}'..."
    VBoxManage controlvm "${VM_NAME}" poweroff 2>/dev/null || true
    VBoxManage unregistervm "${VM_NAME}" --delete
    echo "VM '${VM_NAME}' rimossa."
}

# Funzione per ottenere l'ultima versione della VDI
get_latest_vdi_url() {
    echo "Recupero dell'ultima versione della VDI di Home Assistant OS..."
    LATEST_URL=$(curl -s https://api.github.com/repos/home-assistant/operating-system/releases/latest \
        | grep "browser_download_url.*haos_ova.*\.vdi\.zip" \
        | cut -d '"' -f 4)
    if [[ -z "$LATEST_URL" ]]; then
        echo "Errore: impossibile recuperare l'URL della VDI più recente."
        exit 1
    fi
    echo "Ultima versione trovata: $LATEST_URL"
}

# Funzione per scaricare e preparare la VDI
download_vdi() {
    mkdir -p "$WORK_DIR/$VM_NAME"
    ZIP_FILE="$WORK_DIR/$VM_NAME/$(basename "$LATEST_URL")"
    VDI_FILE="${ZIP_FILE%.zip}"

    echo "Percorso ZIP_FILE: $ZIP_FILE"
    echo "Percorso VDI_FILE: $VDI_FILE"

    if [[ ! -f "$VDI_FILE" ]]; then
        echo "Scaricamento della VDI da: $LATEST_URL..."
        curl -L -o "$ZIP_FILE" "$LATEST_URL"
        echo "Estrazione del file VDI..."
        unzip -o "$ZIP_FILE" -d "$WORK_DIR/$VM_NAME"
    else
        echo "File VDI già presente: $VDI_FILE"
    fi
}

# Funzione per elencare le interfacce di rete disponibili
select_network_interface() {
    echo "Seleziona l'interfaccia di rete da usare per l'adattatore bridged:"
    AVAILABLE_INTERFACES=$(VBoxManage list bridgedifs | grep ^Name | awk -F': ' '{print $2}')
    select NET_INTERFACE in $AVAILABLE_INTERFACES; do
        if [[ -n "$NET_INTERFACE" ]]; then
            echo "Interfaccia selezionata: $NET_INTERFACE"
            break
        else
            echo "Selezione non valida, riprova."
        fi
    done
}

# Funzione per impostare la porta RDP
set_rdp_port() {
    read -p "Inserisci la porta RDP (default: 3389): " RDP_PORT
    RDP_PORT=${RDP_PORT:-3389}
    echo "Porta RDP impostata su: $RDP_PORT"
}

# Funzione per creare e configurare la VM
create_vm() {
    echo "Creazione della Virtual Machine '${VM_NAME}'..."
    VBoxManage createvm --name "${VM_NAME}" --ostype "Linux_64" --register
    VBoxManage modifyvm "${VM_NAME}" --memory "${MEMORY}" --cpus "${CPUS}" --firmware efi
    VBoxManage modifyvm "${VM_NAME}" --audio none --nic1 bridged --bridgeadapter1 "${NET_INTERFACE}"
    VBoxManage modifyvm "${VM_NAME}" --vrde on --vrdeport "${RDP_PORT}" --vrdeaddress 0.0.0.0 --vrdeauthtype null

    echo "Configurazione del disco virtuale..."
    VBoxManage storagectl "${VM_NAME}" --name "SATA" --add sata --controller IntelAhci
    VBoxManage storageattach "${VM_NAME}" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$(realpath "$WORK_DIR/$VM_NAME/$(basename "${VDI_FILE}")")"
}

# Funzione per avviare la VM
start_vm() {
    echo "Avvio della VM '${VM_NAME}' in modalità headless..."
    VBoxManage startvm "${VM_NAME}" --type headless
    echo "VM '${VM_NAME}' avviata con successo."
}

# Funzione per ottenere informazioni sulla VM
get_vm_info() {
    MAC_ADDRESS=$(VBoxManage showvminfo "${VM_NAME}" --machinereadable | grep "macaddress1" | cut -d '"' -f 2)
    MAC_ADDRESS_FORMATTED=$(echo "$MAC_ADDRESS" | sed 's/../&:/g;s/:$//')
    VM_IP=$(VBoxManage guestproperty get "${VM_NAME}" "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{print $2}')
    echo "Dettagli della VM:"
    echo "- MAC Address: $MAC_ADDRESS_FORMATTED"
    echo "- Indirizzo IP: ${VM_IP:-Non disponibile}"
    echo "- Porta RDP: $RDP_PORT"
}

# Variabili di configurazione
VM_NAME="HomeAssistantOS"
MEMORY=2048
CPUS=2
WORK_DIR="$(VBoxManage list systemproperties | grep "Default machine folder" | awk -F': ' '{print $2}' | xargs)"

# Funzione principale
main() {
    check_root
    check_virtualbox
    check_existing_vm
    get_latest_vdi_url
    download_vdi
    select_network_interface
    set_rdp_port
    create_vm
    start_vm
    get_vm_info
    echo "Installazione completata."
}

# Esecuzione dello script
main

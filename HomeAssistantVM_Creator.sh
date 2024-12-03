#!/bin/bash

# Funzione per controllare se VirtualBox è installato
check_virtualbox() {
    if ! command -v VBoxManage &> /dev/null; then
        echo "Error: VirtualBox is not installed. Please install it first."
        exit 1
    fi
}

# Funzione per richiedere e verificare il file VDI
get_vdi_file() {
    echo -n "Enter the name of the VDI file (including path): "
    read VDI_FILE
    if [[ ! -f "$VDI_FILE" ]]; then
        echo "Error: The specified VDI file does not exist."
        exit 1
    fi
}

# Funzione per elencare le interfacce di rete e scegliere una
select_network_interface() {
    echo "Available network interfaces:"
    ip link show | grep -E '^[0-9]+' | awk '{print $2}' | sed 's/://'
    echo -n "Enter the network interface to use for bridged adapter: "
    read NET_INTERFACE
}

# Funzione per richiedere la porta RDP
get_rdp_port() {
    echo -n "Enter the RDP port (default is 3389): "
    read RDP_PORT
    if [[ -z "$RDP_PORT" ]]; then
        RDP_PORT=3389
    fi
}

# Controllo che VirtualBox sia installato
check_virtualbox

# Richiesta del file VDI e verifica dell'esistenza
get_vdi_file

# Elenco e selezione dell'interfaccia di rete
select_network_interface

# Richiesta della porta RDP
get_rdp_port

# Impostazione variabili
VM_NAME="HomeAssistantOS"
MEMORY=2048
CPUS=2

# Creazione della VM
echo "Creating Virtual Machine $VM_NAME..."
VBoxManage createvm --name "$VM_NAME" --ostype "Linux_64" --register
VBoxManage modifyvm "$VM_NAME" --memory $MEMORY --cpus $CPUS --firmware efi
VBoxManage modifyvm "$VM_NAME" --audio none
VBoxManage modifyvm "$VM_NAME" --nic1 bridged --bridgeadapter1 "$NET_INTERFACE"
VBoxManage modifyvm "$VM_NAME" --vrde on --vrdeport $RDP_PORT --vrdeaddress 0.0.0.0 --vrdeauthtype null

# Creazione del controller SATA e spostamento del file VDI
VM_PATH=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -i "CfgFile" | awk -F'"' '{print $2}' | sed 's/\.vbox//')
mkdir -p "$VM_PATH"
cp "$VDI_FILE" "$VM_PATH/"
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VM_PATH/$(basename "$VDI_FILE")"
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --nonrotational on --discard on

# Avvio della VM
echo "Starting the VM in headless mode..."
VBoxManage startvm "$VM_NAME" --type headless

# Recupero e stampa del MAC Address
MAC_ADDRESS=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "macaddress1" | awk -F'=' '{print $2}' | tr -d '"')
MAC_ADDRESS_FORMATTED=$(echo "$MAC_ADDRESS" | sed 's/../&:/g;s/:$//')
echo "Questo è il MAC Address della VM: $MAC_ADDRESS_FORMATTED"

echo "Virtual Machine $VM_NAME created and started successfully with RDP enabled on port $RDP_PORT."

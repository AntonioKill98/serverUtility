#!/bin/bash

# Funzione per richiedere input con un valore predefinito
ask() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Introduzione
echo "=== Configurazione interattiva del bridge ==="

# Richiesta del nome del bridge
BRIDGE_NAME=$(ask "Inserisci il nome del bridge" "br0")

# Elenca tutte le interfacce disponibili
echo "Rilevamento delle interfacce di rete..."
AVAILABLE_INTERFACES=$(ls /sys/class/net | grep -v -E 'lo|br')
INTERFACES_ARRAY=($AVAILABLE_INTERFACES)

# Mostra l'elenco delle interfacce numerato
echo "Seleziona le interfacce da includere nel bridge:"
for i in "${!INTERFACES_ARRAY[@]}"; do
    echo "  [$i] ${INTERFACES_ARRAY[$i]}"
done

# Richiedi la scelta delle interfacce (con numeri separati da spazi)
echo "Inserisci i numeri delle interfacce da includere nel bridge (es. 0 1):"
read -p "Scelta: " -r SELECTED_NUMBERS

# Converti i numeri selezionati in nomi di interfacce
SELECTED_INTERFACES=()
for num in $SELECTED_NUMBERS; do
    SELECTED_INTERFACES+=("${INTERFACES_ARRAY[$num]}")
done

# Verifica interfacce selezionate
if [ ${#SELECTED_INTERFACES[@]} -eq 0 ]; then
    echo "Nessuna interfaccia selezionata. Uscita."
    exit 1
fi

echo "Interfacce selezionate: ${SELECTED_INTERFACES[*]}"

# Percorso del file di configurazione delle interfacce
INTERFACES_FILE="/etc/network/interfaces"

# Crea un backup del file originale
cp "$INTERFACES_FILE" "${INTERFACES_FILE}.backup"

echo "Backup del file originale creato in ${INTERFACES_FILE}.backup"

# Commenta le righe relative alle interfacce coinvolte
for iface in "${SELECTED_INTERFACES[@]}"; do
    sed -i "/^\s*auto\s\+$iface/ s/^/#/" "$INTERFACES_FILE"
    sed -i "/^\s*iface\s\+$iface\s\+/ s/^/#/" "$INTERFACES_FILE"
    echo "Interfaccia $iface commentata nel file di configurazione."
done

# Aggiungi la configurazione del bridge
if ! grep -q "auto $BRIDGE_NAME" "$INTERFACES_FILE"; then
    echo -e "\n# Configurazione del bridge $BRIDGE_NAME" >> "$INTERFACES_FILE"
    echo "auto $BRIDGE_NAME" >> "$INTERFACES_FILE"
    echo "iface $BRIDGE_NAME inet dhcp" >> "$INTERFACES_FILE"
    echo "    bridge_ports ${SELECTED_INTERFACES[*]}" >> "$INTERFACES_FILE"
    echo "Configurazione del bridge $BRIDGE_NAME aggiunta al file."
else
    echo "Il bridge $BRIDGE_NAME è già configurato nel file. Nessuna modifica necessaria."
fi

# Riavvia la rete
echo "Riavvio della rete..."
if systemctl is-active --quiet networking; then
    systemctl restart networking
else
    ifdown "$BRIDGE_NAME" && ifup "$BRIDGE_NAME"
fi

# Verifica lo stato del bridge
echo "Stato del bridge:"
brctl show
ip addr show "$BRIDGE_NAME"

echo "Configurazione completata. Il bridge $BRIDGE_NAME è attivo e include le interfacce: ${SELECTED_INTERFACES[*]}."

#!/bin/bash

# Verifica che lo script sia eseguito come root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Questo script deve essere eseguito come root. Uscita."
        exit 1
    fi
}

# Funzione per richiedere input con un valore predefinito
ask() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Funzione per verificare e avviare systemd-networkd
ensure_networkd_active() {
    echo "Verifica che systemd-networkd sia attivo..."
    if ! systemctl is-active --quiet systemd-networkd; then
        echo "Abilito e avvio systemd-networkd..."
        systemctl enable systemd-networkd
        systemctl start systemd-networkd
    else
        echo "systemd-networkd è già attivo."
    fi
}

# Funzione per rilevare le interfacce di rete disponibili
select_interfaces() {
    echo "Rilevamento delle interfacce di rete disponibili..."
    
    # Filtro per escludere loopback e bridge
    local available_interfaces=$(ls /sys/class/net | grep -v -E '^lo$|^br[0-9]*$')
    local interfaces_array=($available_interfaces)

    if [ ${#interfaces_array[@]} -eq 0 ]; then
        echo "Nessuna interfaccia disponibile per creare il bridge. Uscita."
        exit 1
    fi

    echo "Seleziona le interfacce da includere nel bridge:"
    for i in "${!interfaces_array[@]}"; do
        echo "  [$i] ${interfaces_array[$i]}"
    done

    echo "Inserisci i numeri delle interfacce da includere nel bridge (es. 0 1):"
    read -p "Scelta: " -r selected_numbers

    local selected_interfaces=()
    for num in $selected_numbers; do
        selected_interfaces+=("${interfaces_array[$num]}")
    done

    if [ ${#selected_interfaces[@]} -eq 0 ]; then
        echo "Nessuna interfaccia selezionata. Uscita."
        exit 1
    fi

    echo "Interfacce selezionate: ${selected_interfaces[*]}"
    echo "${selected_interfaces[@]}"
}

# Funzione per commentare le interfacce in /etc/network/interfaces
comment_interfaces_in_file() {
    local interfaces_file="/etc/network/interfaces"
    local selected_interfaces=("$@")

    if [ -f "$interfaces_file" ]; then
        echo "Commento le configurazioni esistenti nel file ${interfaces_file}..."
        for iface in "${selected_interfaces[@]}"; do
            sed -i "/^[^#]*$iface/ s/^/#/" "$interfaces_file"
        done
        echo "Le linee relative alle interfacce ${selected_interfaces[*]} sono state commentate."
    else
        echo "File ${interfaces_file} non trovato. Nessuna azione necessaria."
    fi
}

# Funzione per creare i file di configurazione del bridge
create_bridge_config() {
    local bridge_name="$1"
    local selected_interfaces=("$@")

    # Creazione del file .netdev
    local netdev_file="/etc/systemd/network/${bridge_name}.netdev"
    echo "Creazione del file ${netdev_file}..."
    cat > "${netdev_file}" <<EOF
[NetDev]
Name=${bridge_name}
Kind=bridge
EOF

    # Creazione del file .network per il bridge
    local network_file="/etc/systemd/network/${bridge_name}.network"
    echo "Creazione del file ${network_file}..."
    cat > "${network_file}" <<EOF
[Match]
Name=${bridge_name}

[Network]
DHCP=yes
EOF

    # Creazione dei file .network per le interfacce selezionate
    for iface in "${selected_interfaces[@]:1}"; do
        local iface_file="/etc/systemd/network/${iface}.network"
        echo "Creazione del file ${iface_file}..."
        cat > "${iface_file}" <<EOF
[Match]
Name=${iface}

[Network]
Bridge=${bridge_name}
EOF
    done
}

# Funzione per riavviare systemd-networkd e verificare il bridge
restart_networkd_and_check_bridge() {
    local bridge_name="$1"

    echo "Riavvio di systemd-networkd..."
    systemctl restart systemd-networkd

    echo "Verifica dello stato del bridge..."
    ip link show "${bridge_name}"

    local bridge_mac=$(cat /sys/class/net/${bridge_name}/address 2>/dev/null)
    if [ -z "$bridge_mac" ]; then
        echo "Il MAC address del bridge non è disponibile. Assicurati che il bridge sia stato creato correttamente."
    else
        echo "MAC Address del bridge ${bridge_name}: ${bridge_mac}"
    fi
}

# Funzione principale
main() {
    check_root
    ensure_networkd_active

    local selected_interfaces=($(select_interfaces))
    local bridge_name=$(ask "Inserisci il nome del bridge" "br0")

    comment_interfaces_in_file "${selected_interfaces[@]}"
    create_bridge_config "$bridge_name" "${selected_interfaces[@]}"
    restart_networkd_and_check_bridge "$bridge_name"

    echo "Configurazione del bridge completata!"
}

# Esecuzione dello script
main

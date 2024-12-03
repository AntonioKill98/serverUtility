#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
    echo "Questo script deve essere eseguito come root. Usa sudo."
    exit 1
fi

# Aggiorna il sistema
echo "Aggiornamento del sistema..."
apt update && apt upgrade -y

# Installa i pacchetti richiesti
echo "Installazione dei pacchetti richiesti..."
apt install -y \
    python3 python3-pip python3-venv python3-dev build-essential \
    openjdk-17-jdk openjdk-17-jre \
    xorg pekwm tint2 \
    firefox-esr htop screen glances lxterminal geany \
    transmission-cli transmission-daemon transmission-gtk \
    iperf3 \
    x11-apps xbindkeys xbacklight xinput x11-server-utils

# Configurazione di Transmission con Web UI
echo "Configurazione di Transmission..."
systemctl stop transmission-daemon
cat > /etc/transmission-daemon/settings.json <<EOF
{
    "rpc-enabled": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-port": 9091,
    "rpc-username": "",
    "rpc-password": "",
    "rpc-whitelist": "*.*.*.*",
    "rpc-whitelist-enabled": false
}
EOF
systemctl start transmission-daemon
echo "Transmission Web UI è accessibile su http://<IP-del-server>:9091"

# Configurazione di PekWM
echo "Configurazione di PekWM..."
PEKWM_CONFIG_DIR="$HOME/.pekwm"
mkdir -p "$PEKWM_CONFIG_DIR"
mkdir -p "$PEKWM_CONFIG_DIR/autoproperties"
mkdir -p "$PEKWM_CONFIG_DIR/start"
mkdir -p "$PEKWM_CONFIG_DIR/keys"

# Creazione del file start per avviare Tint2
cat > "$PEKWM_CONFIG_DIR/start" <<EOF
#!/bin/bash
tint2 &
EOF
chmod +x "$PEKWM_CONFIG_DIR/start"

# Configurazione del layout della tastiera
cat > "$PEKWM_CONFIG_DIR/start" <<EOF
#!/bin/bash
setxkbmap it &
tint2 &
EOF

# Creazione del menu di PekWM con i programmi installati
cat > "$PEKWM_CONFIG_DIR/menu" <<EOF
Entry = "Terminal" { Actions = "Exec lxterminal" }
Entry = "Web Browser" { Actions = "Exec firefox-esr" }
Entry = "File Manager" { Actions = "Exec pcmanfm" }
Entry = "Text Editor" { Actions = "Exec geany" }
Entry = "Task Manager" { Actions = "Exec htop" }
Entry = "Glances" { Actions = "Exec glances -w" }
Entry = "Transmission" { Actions = "Exec transmission-gtk" }
EOF

# Configurazione di Glances come servizio web
echo "Configurazione di Glances come servizio web..."
cat > /etc/systemd/system/glances.service <<EOF
[Unit]
Description=Glances Web Server
After=network.target

[Service]
ExecStart=/usr/bin/glances -w
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable glances
systemctl start glances

# Verifica dei servizi
echo "Verifica dei servizi configurati..."
systemctl status transmission-daemon | grep Active
systemctl status glances | grep Active

# Output finale
echo "Setup completato!"
echo "Transmission Web UI è accessibile su http://<IP-del-server>:9091"
echo "Glances Web Server è accessibile su http://<IP-del-server>:61208"

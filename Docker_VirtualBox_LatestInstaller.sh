#!/bin/bash

# Verifica se lo script è eseguito come root
if [[ $EUID -ne 0 ]]; then
   echo "Questo script deve essere eseguito come root. Usa sudo." 
   exit 1
fi

# Aggiornamento dei pacchetti di sistema e installazione delle dipendenze di base
echo "Aggiornamento dei pacchetti di sistema e installazione delle dipendenze..."
apt-get update
apt-get install -y ca-certificates curl

# Creazione della directory per le chiavi APT e scaricamento della chiave GPG ufficiale di Docker
echo "Scaricamento della chiave GPG ufficiale di Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Aggiunta del repository di Docker
echo "Aggiunta del repository ufficiale di Docker a APT sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Aggiornamento dei pacchetti e installazione di Docker
echo "Aggiornamento dei pacchetti e installazione di Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verifica che Docker sia installato correttamente
echo "Verifica dell'installazione di Docker..."
docker --version
if [[ $? -ne 0 ]]; then
    echo "Errore: Docker non è stato installato correttamente."
    exit 1
fi

# Installazione di VirtualBox
echo "Installazione di VirtualBox e del pacchetto Extension Pack..."
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | gpg --dearmor -o /usr/share/keyrings/virtualbox-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/virtualbox-archive-keyring.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/virtualbox.list

apt-get update
apt-get install -y virtualbox virtualbox-ext-pack

# Accettazione automatica della licenza del pacchetto Extension Pack
echo "Accettazione della licenza del VirtualBox Extension Pack..."
echo virtualbox-ext-pack virtualbox-ext-pack/license select true | debconf-set-selections

# Verifica delle installazioni
echo "Verifica delle installazioni..."
docker_version=$(docker --version)
compose_version=$(docker compose version)
vbox_version=$(vboxmanage --version)

echo "Installazioni completate con successo!"
echo "-------------------------------------"
echo "Docker: $docker_version"
echo "Docker Compose Plugin: $compose_version"
echo "VirtualBox: $vbox_version"
echo "VirtualBox Extension Pack: Installato"

# Fine script
echo "Tutto è stato configurato con successo. Lo script è terminato."

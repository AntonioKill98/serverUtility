#!/bin/bash

# Elenco delle porte aperte dai container Docker
echo "== Porte aperte dai container Docker =="
docker ps --format '{{.Names}} {{.Ports}}' | while read -r container ports; do
    if [[ $ports != "" ]]; then
        echo "Container: $container"
        echo "$ports" | sed 's/, /\n/g' | sed 's/^/  - /'
    else
        echo "Container: $container (Nessuna porta esposta)"
    fi
    echo
done

# Elenco delle porte aperte sul sistema principale
echo "== Porte aperte sul sistema principale =="
sudo lsof -i -P -n | awk 'NR==1 || /LISTEN/' | while read -r line; do
    echo "$line"
done | column -t

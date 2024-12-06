#!/bin/bash

# Nome dello script corrente
CURRENT_SCRIPT="Install_All.sh"

# File di log
LOG_FILE="installerLog.log"

# Inizializzazione del file di log
echo "Log inizializzato il $(date)" > "$LOG_FILE"

# Funzione per eseguire uno script con un riquadro di asterischi
execute_script() {
    local script_name="$1"

    while true; do
        echo -e "\033[1;33m****************************************************" | tee -a "$LOG_FILE"
        echo -e "             Esecuzione di: $script_name" | tee -a "$LOG_FILE"
        echo -e "****************************************************\033[0m" | tee -a "$LOG_FILE"
        echo | tee -a "$LOG_FILE"
        echo "Scegli un'opzione:" | tee -a "$LOG_FILE"
        echo "1) Install" | tee -a "$LOG_FILE"
        echo "2) Skip" | tee -a "$LOG_FILE"
        echo "3) Exit" | tee -a "$LOG_FILE"
        read -p "Scelta: " choice

        case $choice in
            1)
                # Verifica se lo script esiste
                if [[ -f "$script_name" ]]; then
                    bash "$script_name" 2>&1 | tee -a "$LOG_FILE"
                    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
                        echo -e "\033[1;32mEsecuzione di $script_name completata con successo.\033[0m" | tee -a "$LOG_FILE"
                    else
                        echo -e "\033[1;31mErrore durante l'esecuzione di $script_name.\033[0m" | tee -a "$LOG_FILE"
                    fi
                else
                    echo -e "\033[1;31mErrore: Lo script $script_name non esiste.\033[0m" | tee -a "$LOG_FILE"
                fi
                break
                ;;
            2)
                echo -e "\033[1;33m$script_name saltato.\033[0m" | tee -a "$LOG_FILE"
                break
                ;;
            3)
                echo -e "\033[1;31mUscita dal processo.\033[0m" | tee -a "$LOG_FILE"
                exit 0
                ;;
            *)
                echo -e "\033[1;31mOpzione non valida. Riprova.\033[0m" | tee -a "$LOG_FILE"
                ;;
        esac
    done
    echo | tee -a "$LOG_FILE"
}

# Generazione dell'elenco degli script ordinati
scripts=($(ls | grep -E '^[0-9]+-.*\.sh$' | sort -V))

# Verifica che ci siano script da eseguire
if [[ ${#scripts[@]} -eq 0 ]]; then
    echo -e "\033[1;31mNessuno script numerato trovato nella directory corrente.\033[0m" | tee -a "$LOG_FILE"
    exit 1
fi

# Esecuzione degli script
for script in "${scripts[@]}"; do
    if [[ "$script" != "$CURRENT_SCRIPT" ]]; then
        execute_script "$script"
    fi
done

echo -e "\033[1;32mTutti gli script sono stati processati in ordine.\033[0m" | tee -a "$LOG_FILE"

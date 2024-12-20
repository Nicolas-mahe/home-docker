#!/bin/bash

# Recover Date
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
echo "Execution time is: $exec_date"

# Extract hour from $exec_date
exec_hour=${exec_date:11:2}  # Les caractères 11 et 12 correspondent à l'heure dans le format YYYY-MM-DD_HH-MM-SS
    TimeToExec=1
# if [ "$exec_hour" -ge 6 ] && [ "$exec_hour" -lt 23 ]; then
#     TimeToExec=0
#     echo "Not First execution of the day, Don't make the all backups"
# fi

# Fonction pour supprimer les fichiers les plus anciens si le nombre de fichiers dépasse $NbBackups
NbBackups=10
delete_old_files() {
    local directory="$1"  # work's directory
    local prefix="$2"     # Prefix of files
    
    # Check if directory exists
    if [[ ! -d "$directory" ]]; then
        echo "Directory $directory not found."
        return 1
    else 
        echo "Check backups number in $directory:"
    fi

    # Lister les fichiers qui correspondent au préfixe et les compter
    local files=("$directory"/"$prefix"*)
    local file_count=0

    # Vérifiez si les fichiers existent avant d'essayer de compter
    if [[ -e "${files[0]}" ]]; then
        file_count=${#files[@]}
    fi

    # Vérifier si le nombre de fichiers dépasse $NbBackups
    if (( file_count > $NbBackups )); then
        echo "There is $file_count (>$NbBackups) files match with prefix '$prefix', purge older(s)..."

        # Trier les fichiers par la partie de leur nom correspondant à la date
        local sorted_files
        sorted_files=$(printf '%s\n' "${files[@]}" | \
            awk -F"${prefix}" '{if (NF > 1) print $2, $0}' | \
            sort | \
            awk '{print $2}')

        # Supprimer les fichiers les plus anciens, en gardant les $NbBackups plus récents
        local files_to_delete
        files_to_delete=$(echo "$sorted_files" | head -n $((${file_count} - $NbBackups)))
    ##DEBUG
    # echo "Sorted files: $sorted_files"
    # echo "Files to delete: $files_to_delete"
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then  # Vérifie que c'est un fichier valide
                rm -f "$file"
                echo "File deleted : $file"
            else
                echo "Skipping invalid file: $file"
            fi
        done <<< "$files_to_delete"
    else
        echo "There is $file_count (=<$NbBackups) files match with prefix '$prefix', no purge needed"
    fi
}

# Set Path
read -r PathRaid < ../docker/docker-secret/global/RAID_DATA_DIRECTORY.txt
BackupsPath="/$PathRaid/backups/ExternalBackup/Server-Backups"
read -r EncryptionKey < ../docker/docker-secret/portainer/PortainerEncryption.txt

# # Déclaration du tableau associatif
# declare -A backups

# # Ajout des données
# backups["Duplicati"]="/$PathRaid/users/rabbyt/Documents/Config/Serveur/Duplicati"
# backups["Portainer"]="/$PathRaid/users/rabbyt/Documents/Config/Serveur/Portainer"

# # Copie des données
# for key in "${!backups[@]}"; do
#     echo "Copy backups $key's files" 
#     cp -r "${backups[$key]}" $BackupsPath/$key
# done

if [ "$TimeToExec" ]; then
    
    # VaultWardenVaultExport
    echo "Export Vault from Vaultwarden"
    vaultwarden_filename="bitwarden_encrypted_export_$exec_date"
    ./VaultwardenVaultExport.sh "$vaultwarden_filename" "$BackupsPath"

    # Portainer
    read -r PortainerApiKey < ../docker/docker-secret/portainer/APIKEY.txt
    read -r PortainerLocalPort < ../docker/docker-secret/portainer/PERSONNAL_PORTAINER_PORT.txt
    curl -X POST "http://localhost:$PortainerLocalPort/api/backup" \
    -H "X-API-Key: $PortainerApiKey" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"$EncryptionKey\"}" \
    --output "$BackupsPath/Portainer/portainer_config_encrypted_backup_$exec_date.tar.gz"

    # OpenMediaVault config
    echo "Export OpenMediaVault config"
    tar -czf  "$BackupsPath/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz" -C /etc/openmediavault/ config.xml
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric \
        --cipher-algo AES256 "$BackupsPath/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz"
    rm $BackupsPath/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz

    # Important docker config files
    echo "Export container configs"
    docker_path="../docker/docker-data"
    docker_config=(
        "adguard/conf"
        "homepage/config"
        "traefik/conf"
        "vaultwarden/config.json"
        "nextcloud/config/www/nextcloud/config"
        "duplicati/"
        )
    tar -czf  "docker_apps_config_backup_$exec_date.tar.gz" -C "$docker_path" "${docker_config[@]}"
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric --cipher-algo AES256 -o "$BackupsPath/DockerAppConfig/docker_apps_config_backup_$exec_date.tar.gz.gpg" "docker_apps_config_backup_$exec_date.tar.gz"
    rm docker_apps_config_backup_$exec_date.tar.gz

    # Traefik stack data
    echo "Export traefik stack volumes"
    tar -czf  "traefik_stack_backup_$exec_date.tar.gz" -C "../docker/docker-data/" "traefik"
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric --cipher-algo AES256 -o "$BackupsPath/DockerAppConfig/traefik_stack_backup_$exec_date.tar.gz.gpg" "traefik_stack_backup_$exec_date.tar.gz"
    rm traefik_stack_backup_$exec_date.tar.gz

fi
delete_old_files "$BackupsPath/Vaultwarden" "bitwarden_encrypted_export_"
delete_old_files "$BackupsPath/Portainer" "portainer_config_encrypted_backup_"
delete_old_files "$BackupsPath/OpenMediaVault" "openmediavault_config_backup_"
delete_old_files "$BackupsPath/DockerAppConfig" "docker_apps_config_backup_"
delete_old_files "$BackupsPath/DockerAppConfig" "traefik_stack_backup_"

# Apply owner to directory
echo "Apply owner to backups files"
chown -R docker:maison $BackupsPath
chmod -R 771 $BackupsPath
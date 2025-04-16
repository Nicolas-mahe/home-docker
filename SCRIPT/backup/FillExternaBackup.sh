#!/bin/bash

# Recover Date
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
echo "Execution time is: $exec_date"

# Extract hour from $exec_date
exec_hour=${exec_date:11:2}  # Extraction de l'heure à partir du format YYYY-MM-DD_HH-MM-SS
exec_day_of_week=$(date -d "${exec_date:0:10}" +%u)  # Extraction du jour de la semaine (1 = lundi, ..., 7 = dimanche)
if [[ "$exec_hour" =~ ^[0-9]+$ && "$exec_day_of_week" =~ ^[0-9]+$ ]]; then
    if (( exec_hour <= 6 || exec_hour >= 23 )); then
        if (( exec_day_of_week == 1 )); then
            echo "It's Monday, Run all backups"
            TimeToExec="1"
        else
            echo "It's not Monday, Run minimal backups"
            TimeToExec="2"
        fi
    else
        echo "Not First execution of the day, Don't make the all backups"
        TimeToExec="0"
    fi
else
    echo "Erreur : exec_hour ($exec_hour) et/ou exec_day_of_week ($exec_day_of_week) n'est pas un nombre valide"
fi

# Fonction pour supprimer les fichiers les plus anciens si le nombre de fichiers dépasse $NbBackups
delete_old_files() {
    local directory="$1"  # work's directory
    local prefix="$2"     # Prefix of files
    local NbBackups="${3:-10}"  # Max Number of files to keep (10 by default)

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
#Recover Execution path
Script_Dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Data_Dir="/$(echo "$Script_Dir" | cut -d'/' -f2)"

#Test is path is in root directory
if [[ "$Data_Dir" == "//" ]]; then
    Data_Dir="/"
fi
#echo "Folder container data is : $Data_Dir"

# Set Path
read -r PathRaid < $Data_Dir/docker/docker-secret/global/RAID_DATA_DIRECTORY.txt
Backups_Path="/$PathRaid/backups"
Backups_Apps_Path="$Backups_Path/Apps-conf"
Docker_Path="$Data_Dir/docker/docker-data"
Script_Path="$Data_Dir/repos/home-docker/SCRIPT"

read -r EncryptionKey < $Data_Dir/docker/docker-secret/portainer/PortainerEncryption.txt


if [ "$TimeToExec" -eq 1 ]; then
    
    # VaultWardenVaultExport
    echo "Export Vault from Vaultwarden"
    vaultwarden_filename="bitwarden_encrypted_export_$exec_date"
    $Script_Path/backup/VaultwardenVaultExport.sh "$vaultwarden_filename" "$Backups_Apps_Path"

    # Portainer
    read -r PortainerApiKey < $Data_Dir/docker/docker-secret/portainer/APIKEY.txt
    read -r PortainerLocalPort < $Data_Dir/docker/docker-secret/portainer/PERSONNAL_PORTAINER_PORT.txt
    curl -X POST "http://localhost:$PortainerLocalPort/api/backup" \
    -H "X-API-Key: $PortainerApiKey" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"$EncryptionKey\"}" \
    --output "$Backups_Apps_Path/Portainer/portainer_config_encrypted_backup_$exec_date.tar.gz"

    # OpenMediaVault config
    echo "Export OpenMediaVault config"
    tar -czf  "$Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz" -C /etc/openmediavault/ config.xml
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric \
        --cipher-algo AES256 "$Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz"
    rm $Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz

    # Important docker config files
    echo "Export container configs"
    Docker_Config=(
        "adguard/conf"
        "homepage/config"
        "traefik/conf"
        "vaultwarden/config.json"
        "nextcloud/config/www/nextcloud/config"
        "nextcloud/config/php"
        "duplicati/"
        )
    tar -czf  "docker_apps_config_backup_$exec_date.tar.gz" -C "$Docker_Path" "${Docker_Config[@]}"
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric --cipher-algo AES256 -o "$Backups_Apps_Path/DockerAppConfig/docker_apps_config_backup_$exec_date.tar.gz.gpg" "docker_apps_config_backup_$exec_date.tar.gz"
    rm docker_apps_config_backup_$exec_date.tar.gz

    # Traefik stack data
    echo "Export traefik stack volumes"
    tar -czf  "traefik_stack_backup_$exec_date.tar.gz" -C "$Data_Dir/docker/docker-data/" "traefik"
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric --cipher-algo AES256 -o "$Backups_Apps_Path/DockerAppConfig/traefik_stack_backup_$exec_date.tar.gz.gpg" "traefik_stack_backup_$exec_date.tar.gz"
    rm traefik_stack_backup_$exec_date.tar.gz

fi

# Minecraft managment
Minecraft_Path="$Docker_Path/minecraft/s5/prod/backups"
Minecraft_Backups_Path="$Backups_Path/Minecraft/s5"
if [ "$TimeToExec" -eq 2 ]; then
    if [[ ! -d "$Minecraft_Path" ]]; then
        echo "Directory $Minecraft_Path not found."
    else 
        # Find newer backups.zip
        Minecraft_Recent_Backup=$(ls -t "$Minecraft_Path"/*.zip 2>/dev/null | head -n 1)
        if [[ -z "$Minecraft_Recent_Backup" ]]; then
            echo "No backups.zip files found in $Minecraft_Path."
        fi

        # Copy it in folder if not already exist
        Minecraft_Newer_Backups=$(basename "$Minecraft_Recent_Backup")
        Minecraft_Recent_Backup_Save=$(ls -t "$Minecraft_Backups_Path/$Minecraft_Newer_Backups" 2>/dev/null)
        if [[ ! -z "$Minecraft_Recent_Backup_Save" ]]; then
            echo "Minecraft backups $Minecraft_Newer_Backups already in $Minecraft_Backups_Path"
        else
            cp "$Minecraft_Recent_Backup" "$Minecraft_Backups_Path"
            echo "Copied $Minecraft_Recent_Backup to $Minecraft_Backups_Path"
        fi
    fi
fi

# Delete older files
delete_old_files "$Backups_Apps_Path/Vaultwarden" "bitwarden_encrypted_export_"
delete_old_files "$Backups_Apps_Path/Portainer" "portainer_config_encrypted_backup_"
delete_old_files "$Backups_Apps_Path/OpenMediaVault" "openmediavault_config_backup_"
delete_old_files "$Backups_Apps_Path/DockerAppConfig" "docker_apps_config_backup_"
delete_old_files "$Backups_Apps_Path/DockerAppConfig" "traefik_stack_backup_"
delete_old_files "$Minecraft_Backups_Path" "20" "5"

# Apply owner to directory
echo "Apply owner to backups files"
chown -R docker:maison $Backups_Path
chmod -R 775 $Backups_Path
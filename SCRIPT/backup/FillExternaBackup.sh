#!/bin/bash

# Définition des couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Recover Date
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
log_info "Execution time is: $exec_date"

# Extract hour from $exec_date
exec_hour=${exec_date:11:2}  # Extraction de l'heure à partir du format YYYY-MM-DD_HH-MM-SS
exec_day_of_week=$(date -d "${exec_date:0:10}" +%u)  # Extraction du jour de la semaine (1 = lundi, ..., 7 = dimanche)
if [[ "$exec_hour" =~ ^[0-9]+$ && "$exec_day_of_week" =~ ^[0-9]+$ ]]; then
    if (( exec_hour <= 6 || exec_hour >= 23 )); then
        if (( exec_day_of_week == 1 )); then
            log_info "It's Monday, Run all backups"
            TimeToExec="1"
        else
            log_info "It's not Monday, Run minimal backups"
            TimeToExec="2"
        fi
    else
        log_info "Not First execution of the day, Don't make the all backups"
        TimeToExec="0"
    fi
else
    log_error "Erreur : exec_hour ($exec_hour) et/ou exec_day_of_week ($exec_day_of_week) n'est pas un nombre valide"
fi

# Fonction pour supprimer les fichiers les plus anciens si le nombre de fichiers dépasse $NbBackups
delete_old_files() {
    local directory="$1"        # work's directory
    local prefix="$2"           # Prefix of files
    local NbBackups="${3:-10}"  # Max Number of files to keep (10 by default)

    # Check if directory exists
    if [[ ! -d "$directory" ]]; then
        log_error "Directory $directory not found."
        return 1
    else 
        log_info "Check backups number in $directory:"
    fi

    # Utiliser un tableau pour stocker les fichiers
    local -a files=()
    local file_count=0
    
    # Fonction pour ajouter un fichier au tableau
    while IFS= read -r -d '' file_path; do
        files+=("$file_path")
        ((file_count++))
    done < <(find "$directory" -type f -name "${prefix}*" -print0)
    
    if (( file_count > NbBackups )); then
        log_warning "There is $file_count (>$NbBackups) files match with prefix '$prefix', purge older(s)..."
        
        # Trier les fichiers par date de modification (du plus récent au plus ancien)
        local -a sorted_files=()
        local sort_command="ls -tr"
        for file in "${files[@]}"; do
            sort_command+=" $(printf '%q' "$file")"
        done
        
        # Exécuter la commande de tri et stocker les résultats
        while IFS= read -r file_path; do
            sorted_files+=("$file_path")
        done < <(eval "$sort_command")
        
        # Calculer le nombre de fichiers à supprimer
        local to_delete=$((file_count - NbBackups))
        
        # Supprimer les fichiers les plus anciens
        for ((i=0; i<to_delete; i++)); do
            local file="${sorted_files[$i]}"
            if [[ -f "$file" ]]; then  # Vérifie que c'est un fichier valide
                rm -f "$file"
                log_success "File deleted: $file"
            else
                log_warning "Skipping invalid file: $file"
            fi
        done
    else
        log_success "There is $file_count (=<$NbBackups) files match with prefix '$prefix', no purge needed"
    fi
}

# Function to check if path is reachable on remote server
check_remote_path() {
    local remote_user="$1"
    local remote_server="$2"
    local remote_ssh_port="${3:-22}"
    local remote_path="$4"

    ssh -q -o "StrictHostKeyChecking=no" -p "$remote_ssh_port" "$remote_user@$remote_server" "test -d $remote_path"
    if [ $? -ne 0 ]; then
        # Remote path not found
        return 2
    else
        # Remote path found
        return 0
    fi
}

# Function to copy files from remote server
copy_files_from_remote_server() {
    local remote_user="$1"
    local remote_server="$2"
    local remote_ssh_port="$3"
    local remote_path="$4"
    local local_path="$5"
    local file_extension="$6"
    # Check if remote path is reachable
    check_remote_path "$remote_user" "$remote_server" "$remote_ssh_port" "$remote_path"

    # If reachable, select newest file to copy
    local remote_file_path
    if [ $? -eq 0 ]; then
        remote_file_path=$(ssh -q -o "StrictHostKeyChecking=no" -p "$remote_ssh_port" "$remote_user@$remote_server" "ls -t $remote_path/*.$file_extension  2>/dev/null | head -n 1")
        
        if [ -z "$remote_file_path" ]; then
            # No files found with extension .$file_extension in $remote_path on $remote_server
            return 5
        fi

        # Get the filename from the remote path
        local filename=$(basename "$remote_file_path")
        local destination_file="$local_path/$filename"

        # Check if file already exists at destination
        if [ -f "$destination_file" ]; then
            log_warning "File $filename already exists at destination, skipping copy"
            return 0
        fi

        # Copy file to local
        log_info "Copying file from $remote_server:$remote_path to $local_path"
        scp -P "$remote_ssh_port" "$remote_user@$remote_server:$remote_file_path" "$local_path"
        return $?
    else
        log_error "Remote path $remote_path not found on $remote_server"
        return $?
    fi
}

# Function to copy files from local path
copy_files_from_local_path() {
    local source_path="$1"
    local local_path="$2"
    local file_extension="$3"    
    local source_file_path

    # Check if source path exists
    if [ ! -d "$source_path" ]; then
        # Source path $source_path not found"
        return 3
    else
        source_file_path=$(ls -t "$source_path"/*."$file_extension" 2>/dev/null | head -n 1)
        if [ -z "$source_file_path" ]; then
            # No files with extension .$file_extension found in $source_path
            return 4
        else
            # Get the filename from the source path
            local filename=$(basename "$source_file_path")
            local destination_file="$local_path/$filename"

            # Check if file already exists at destination
            if [ -f "$destination_file" ]; then
                log_warning "File $filename already exists at destination, skipping copy"
                return 0
            fi

            # Copy the file
            cp "$source_file_path" "$local_path"
            log_success "File copied successfully: $filename"
            return 0
        fi
    fi
}


#Recover Execution path
Script_Dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Data_Dir="/$(echo "$Script_Dir" | cut -d'/' -f2)"

#Test is path is in root directory
if [[ "$Data_Dir" == "//" ]]; then
    Data_Dir="/"
fi
log_info "Folder container data is : $Data_Dir"
# log_info "Script path is : $Script_Dir"

# Set Path
read -r PathRaid < $Data_Dir/docker/docker-secret/global/RAID_DATA_DIRECTORY.txt
Backups_Path="/$PathRaid/backups"
Backups_Apps_Path="$Backups_Path/Apps-conf"
Docker_Path="$Data_Dir/docker/docker-data"
Script_Path="$Data_Dir/repos/home-docker/SCRIPT"

read -r EncryptionKey < $Data_Dir/docker/docker-secret/portainer/PortainerEncryption.txt

# Application managment
if [ "$TimeToExec" -eq 1 ]; then
    
    log_info "${CYAN}=== VaultWarden Backup ===${NC}"
    # VaultWardenVaultExport
    log_info "Export Vault from Vaultwarden"
    vaultwarden_filename="bitwarden_encrypted_export_$exec_date"
    
    # Vérifier l'existence des fichiers nécessaires pour Vaultwarden
    if [ ! -f "$Data_Dir/docker/docker-secret/vaultwarden/VW_CLIENTID.txt" ] || [ ! -f "$Data_Dir/docker/docker-secret/vaultwarden/VW_CLIENTSECRET.txt" ]; then
        log_error "Missing Vaultwarden configuration files. Skipping Vaultwarden backup."
    else
        $Script_Path/backup/VaultwardenVaultExport.sh "$vaultwarden_filename" "$Backups_Apps_Path"
    fi

    log_info "${CYAN}=== Portainer Backup ===${NC}"
    # Portainer
    read -r PortainerApiKey < $Data_Dir/docker/docker-secret/portainer/APIKEY.txt
    read -r PortainerLocalPort < $Data_Dir/docker/docker-secret/portainer/PERSONNAL_PORTAINER_PORT.txt
    log_info "Export Portainer configuration"
    curl -X POST "http://localhost:$PortainerLocalPort/api/backup" \
    -H "X-API-Key: $PortainerApiKey" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"$EncryptionKey\"}" \
    --output "$Backups_Apps_Path/Portainer/portainer_config_encrypted_backup_$exec_date.tar.gz"

    log_info "${CYAN}=== OpenMediaVault Backup ===${NC}"
    # OpenMediaVault config
    log_info "Export OpenMediaVault config"
    tar -czf  "$Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz" -C /etc/openmediavault/ config.xml
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric \
        --cipher-algo AES256 "$Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz"
    rm $Backups_Apps_Path/OpenMediaVault/openmediavault_config_backup_$exec_date.tar.gz

    log_info "${CYAN}=== Docker Apps Config Backup ===${NC}"
    # Important docker config files
    log_info "Export container configs"
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

    log_info "${CYAN}=== Traefik Stack Backup ===${NC}"
    # Traefik stack data
    log_info "Export traefik stack volumes"
    tar -czf  "traefik_stack_backup_$exec_date.tar.gz" -C "$Data_Dir/docker/docker-data/" "traefik"
    gpg --batch --yes --passphrase "$EncryptionKey" --symmetric --cipher-algo AES256 -o "$Backups_Apps_Path/DockerAppConfig/traefik_stack_backup_$exec_date.tar.gz.gpg" "traefik_stack_backup_$exec_date.tar.gz"
    rm traefik_stack_backup_$exec_date.tar.gz

fi

# Games managment
read -r Remote_Games_addr < $Data_Dir/docker/docker-secret/common/Remote_Games_SRV_addr.txt
read -r Remote_Games_port < $Data_Dir/docker/docker-secret/common/Remote_Games_SRV_port.txt

# Minecraft vars
Minecraft_Path="$Docker_Path/minecraft/s5/prod/backups"
Minecraft_Backups_Path="$Backups_Path/games/Minecraft/s5"
Minecraft_Backups_Extension="zip"

# PalWorld vars
PalWorld_Path="$Docker_Path/palworld/games/common/PalServer/Pal/Saved/SaveGames/0/39B9ABFE445430F386A231B68504F49A"
PalWorld_Backups_Path="$Backups_Path/games/PalWorld/s1"
PalWorld_Backups_Extension="????"

# Satisfactory vars
Satisfactory_Path="$Docker_Path/satisfactory/backups"
Satisfactory_Backups_Path="$Backups_Path/games/Satisfactory/s1"
Satisfactory_Backups_Extension="sav"

if [ "$TimeToExec" -eq 1 ] || [ "$TimeToExec" -eq 2 ]; then
    # Minecraft
    log_info "${CYAN}=== Minecraft Backup ===${NC}"
    log_info "Attempting to backup Minecraft files..."
    mkdir -p "$Minecraft_Backups_Path"
    {
        # Command to copy Minecraft backup
        copy_files_from_local_path "$Minecraft_Path" "$Minecraft_Backups_Path" "$Minecraft_Backups_Extension"
    } || {
        # This block executes if the previous command failed (returned non-zero)
        log_warning "Failed to backup Minecraft save from local path. Error code: $? try to backup from remote server"
        copy_files_from_remote_server "docker" "$Remote_Games_addr" "$Remote_Games_port" "$Minecraft_Path" "$Minecraft_Backups_Path" "$Minecraft_Backups_Extension"
        # Additional error handling code can go here
    }|| {
        # This block executes if the previous command failed (returned non-zero)
        log_error "Failed to backup Minecraft save from remote server docker@$Remote_Games_addr:$Remote_Games_port. Error code: $?"
        # Additional error handling code can go here
    }

    # # PalWorld
    # log_info "${CYAN}=== PalWorld Backup ===${NC}"
    # log_info "Attempting to backup PalWorld files..."
    # mkdir -p "$PalWorld_Backups_Path"
    # {
    #     # Command to copy Minecraft backup
    #     copy_files_from_local_path "$PalWorld_Path" "$PalWorld_Backups_Path" "$PalWorld_Backups_Extension"
    # } || {
    #     # This block executes if the previous command failed (returned non-zero)
    #     log_warning "Failed to backup PalWorld save from local path. Error code: $? try to backup from remote server"
    #     copy_files_from_remote_server "docker" "$Remote_Games_addr" "$Remote_Games_port" "$PalWorld_Path" "$PalWorld_Backups_Path" "$PalWorld_Backups_Extension"
    #     # Additional error handling code can go here
    # }|| {
    #     # This block executes if the previous command failed (returned non-zero)
    #     log_error "Failed to backup Satisfactory save from remote server docker@$Remote_Games_addr:$Remote_Games_port. Error code: $?"
    #     # Additional error handling code can go here
    # }

    # Satisfactory
    log_info "${CYAN}=== Satisfactory Backup ===${NC}"
    log_info "Attempting to backup Satisfactory files..."
    mkdir -p "$Satisfactory_Backups_Path"
    {
        # Command to copy Minecraft backup
        copy_files_from_local_path "$Satisfactory_Path" "$Satisfactory_Backups_Path" "$Satisfactory_Backups_Extension"
    } || {
        # This block executes if the previous command failed (returned non-zero)
        log_warning "Failed to backup Satisfactory save from local path. Error code: $? try to backup from remote server"
        copy_files_from_remote_server "docker" "$Remote_Games_addr" "$Remote_Games_port" "$Satisfactory_Path" "$Satisfactory_Backups_Path" "$Satisfactory_Backups_Extension"
        # Additional error handling code can go here
    }|| {
        # This block executes if the previous command failed (returned non-zero)
        log_error "Failed to backup Satisfactory save from remote server docker@$Remote_Games_addr:$Remote_Games_port. Error code: $?"
        # Additional error handling code can go here
    }

fi

# Delete older files
log_info "${PURPLE}=== Cleaning old backup files ===${NC}"
Games_Retention_Days=5
delete_old_files "$Backups_Apps_Path/Vaultwarden" "bitwarden_encrypted_export_" ""
delete_old_files "$Backups_Apps_Path/Portainer" "portainer_config_encrypted_backup_" ""
delete_old_files "$Backups_Apps_Path/OpenMediaVault" "openmediavault_config_backup_" ""
delete_old_files "$Backups_Apps_Path/DockerAppConfig" "docker_apps_config_backup_" ""
delete_old_files "$Backups_Apps_Path/DockerAppConfig" "traefik_stack_backup_" ""
delete_old_files "$Minecraft_Backups_Path" "20" "$Games_Retention_Days"
delete_old_files "$Satisfactory_Backups_Path" "Les" "$Games_Retention_Days"
# delete_old_files "$PalWorld_Backups_Path" "Pal" "$Games_Retention_Days"

# Apply owner to directory
log_info "${GREEN}=== Setting permissions ===${NC}"
log_info "Apply owner to backups files"
chown -R docker:maison $Backups_Path
chmod -R 775 $Backups_Path
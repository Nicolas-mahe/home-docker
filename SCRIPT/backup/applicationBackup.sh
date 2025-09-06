#!/bin/bash

#===============================================================================
# CONFIGURATION
#===============================================================================

# Color definitions for logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#===============================================================================
# FUNCTIONS
#===============================================================================

# Log functions for different message types
log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $1" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Delete old files if the number of files exceeds $NbBackups
# Parameters:
#   $1 - directory: Working directory path
#   $2 - prefix: File prefix pattern (optional)
#   $3 - suffix: File suffix pattern (optional)
#   $4 - NbBackups: Maximum number of files to keep (default: 2)
# Returns:
#   0 if successful, 1 if directory not found
delete_old_files() {
    local directory="$1"
    local prefix="$2"
    local suffix="$3"
    local NbBackups="${4:-2}"

    # Directory validation
    if [[ ! -d "$directory" ]]; then
        log_error "Directory $directory not found."
        return 1
    else 
        log_info "Check backups number in $directory:"
    fi

    # Build pattern for find command
    local pattern="*"
    [[ -n "$prefix" ]] && pattern="${prefix}*"
    [[ -n "$suffix" ]] && pattern="${pattern}${suffix}"

    # Get list of matching files
    local -a files=()
    while IFS= read -r -d '' file_path; do
        files+=("$file_path")
    done < <(find "$directory" -type f -name "$pattern" -print0)

    local file_count=${#files[@]}
    
    if (( file_count > NbBackups )); then
        log_warning "There are $file_count (>$NbBackups) files matching '$pattern', purge older(s)..."

        # Sort files from oldest to newest
        local -a sorted_files=()
        while IFS= read -r file_path; do
            sorted_files+=("$file_path")
        done < <(ls -1tr "${files[@]}")

        # Calculate number of files to delete
        local to_delete=$((file_count - NbBackups))

        # Delete oldest files
        for i in $(seq 0 $((to_delete - 1)))
        do
            local file="${sorted_files[$i]}"
            if [[ -f "$file" ]]; then
                # rm -f "$file"
                log_success "File deleted: $file"
            else
                log_warning "Skipping invalid file: $file"
            fi
        done
    else
        log_success "There are $file_count (=<$NbBackups) files matching '$pattern', no purge needed"
    fi
}

get_container_env() {
    local cid="$1"
    if [ -z "$cid" ]; then
        echo "Usage: get_container_env <container_id_or_name>"
        return 1
    fi

    declare -gA CONTAINER_ENV=()

    while IFS= read -r line; do
        # Ignore lignes vides
        [ -z "$line" ] && continue

        # Extraire la clé et la valeur séparées par le premier '='
        local key="${line%%=*}"
        local value="${line#*=}"

        # Remplacer les caractères invalides dans la clé par des '_'
        key="${key//[^a-zA-Z0-9_]/_}"

        CONTAINER_ENV["$key"]="$value"
    done < <(docker exec "$cid" env)
} # get_container_env "$(get_container_info "${APP_CONFIG[0]}" "${APP_CONFIG[1]}" | jq -r '.ID')"
  # echo "${CONTAINER_ENV[PGDATA]}"

# Generic function to get container information
# Parameters:
#   $1 - container name to search for
#   $2 - search mode (optional, defaults to 'exact')
# Modes:
#   - exact: Match the exact container name
#   - startswith: Match containers whose names start with the given string
#   - endswith: Match containers whose names end with the given string
#   - contains: Match containers whose names contain the given string
# Returns:
#   JSON formatted container information if found
get_container_info() {
    local cname="$1"
    local mode="${2:-exact}"  # default mode = exact
    local pattern

    case "$mode" in
        exact)
            pattern="^${cname}$"
            ;;
        startswith)
            pattern="^${cname}"
            ;;
        endswith)
            pattern="${cname}$"
            ;;
        contains)
            pattern="${cname}"
            ;;
        *)
            log_error "Unknown mode: $mode"
            return 1
            ;;
    esac
    
    log_info "Searching for container ($mode match): $pattern"
    docker ps -f "name=${pattern}" --format '{{json .}}' --no-trunc
}

# Function to perform backup of a container application
# Parameters:
#   $1 - AppName: Name of the application/container
#   $2 - Cpattern: Container name pattern (optional)
#   $3 - CommandToRun: Backup command to execute in the container
#   $4 - BackupFolderName: Name of the folder containing backups
#   $5 - BackupPrefix: Prefix for backup files (optional)
#   $6 - BackupSuffix: Suffix for backup files (optional)
#   $7 - BackupRetention: Number of backups to retain (default: 2)
# Returns:
#   0 if backup successful, 1 if failed, 2 if container not found
perform_backup() {
    local AppName="$1"
    local Cpattern="$2"
    local CommandToRun="$3"
    local BackupFolderName="$4"
    local BackupPrefix="${5:-}"
    local BackupSuffix="${6:-}"
    local BackupRetention="${7:-2}"
    local return_code=0
    local HostBackupPath
    local container_id
    local container_name
    local container_status
    local command_to_execute
    local container_info

    log_info "Starting $AppName backup process..."
    container_info=$(get_container_info "$AppName" "$Cpattern")

    if [ -n "$container_info" ]; then
        # Extract container information
        container_id=$(echo "$container_info" | jq -r '.ID')
        container_name=$(echo "$container_info" | jq -r '.Names')
        container_status=$(echo "$container_info" | jq -r '.Status')
        HostBackupPath=$(echo "$container_info" | jq -r '.Mounts' | tr ',' '\n')
        get_container_env "$(echo "$container_info" | jq -r '.ID')"

        log_info "Container found: ID=$container_id, Name=$container_name, Status=$container_status"
        
        # Interpret vars in command
        if [[ -n "${CONTAINER_ENV[POSTGRES_USER]}" ]]; then
            command_to_execute="${CommandToRun/__POSTGRES_USER__/${CONTAINER_ENV[POSTGRES_USER]}}"
        else
            command_to_execute="$CommandToRun"
        fi
        log_info "Executing command: docker exec -t $container_id $command_to_execute"

        # docker exec -t "$container_id" $command_to_execute
        # Check if backup was successful
        if [ $? -eq 0 ]; then
            log_success "$AppName backup completed successfully"
        else
            log_error "$AppName backup failed"
            return_code=1
        fi

        # Clean up old backup files if backup was successful and HostBackupPath is contains values with '/'
        if [[ $return_code -eq 0 && -n "$HostBackupPath" && "$HostBackupPath" == */* ]]; then
            log_info "Checking backup paths: $HostBackupPath"

            for path in $HostBackupPath; do
                if ls "$path" | grep -q "$BackupFolderName"; then
                    delete_old_files "$path/$BackupFolderName" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
                fi
            done
        else
            log_info "No valid backup paths found, skipping old backup cleanup."
        fi
    else
        log_warning "$AppName container not found or not running, skipping ..."
        return_code=2
    fi

    return $return_code
}

#===============================================================================
# INITIALIZATION
#===============================================================================

# Set execution date for backup naming
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
log_info "Starting backup process at: $exec_date"

#===============================================================================
# MAIN EXECUTION
#===============================================================================

# GitLab
APP_CONFIG=(
    "gitlab"
    "endswith"
    "gitlab-backup create"
    "backups"
    ""
    "gitlab_backup.tar"
    "2"
)
# get_container_env "$(get_container_info "${APP_CONFIG[0]}" "${APP_CONFIG[1]}" | jq -r '.ID')"
perform_backup "${APP_CONFIG[@]}"

# Postgres
APP_CONFIG=(
    'postgres'
    'endswith'
    "pg_dumpall -U __POSTGRES_USER__" # > /home/rabbyt/docker/docker-backups/postgres/${AppName}_backup.sql
    'backups'
    ''
    'postgres_backup.sql'
    '2'
)
perform_backup "${APP_CONFIG[@]}"

log_success "Script completed successfully"

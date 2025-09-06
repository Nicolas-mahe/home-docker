#!/bin/bash

#===============================================================================
# CONFIGURATION
#===============================================================================

# Color definitions for logs
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

#===============================================================================
# FUNCTIONS
#===============================================================================

# Log functions for different message types
log_debug() { echo -e "${PURPLE}[D]${NC} $1" >&2; }
log_info() { echo -e "${BLUE}[I]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[S]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[W]${NC} $1" >&2; }
log_error() { echo -e "${RED}[E]${NC} $1" >&2; }

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
    
    docker ps -f "name=${pattern}" --format '{{json .}}' --no-trunc
}

# Function to perform backup of a container application
# Parameters:
#   $1 - AppName: Name of the application/container
#   $2 - Cpattern: Container name pattern (optional) see 'get_container_info'
#   $3 - CommandToRun: Command to execute in the container
#   $4 - BackupFolderName: Name of the folder containing backups on host
#   $5 - BackupPrefix: Prefix for backup files to sort (optional)
#   $6 - BackupSuffix: Suffix for backup files to sort (optional)
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
    local BackupFileName="${BackupPrefix}_${exec_date}_${BackupSuffix}"
    local return_code=0
    local container_mounts
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
        container_mounts=$(echo "$container_info" | jq -r '.Mounts' | tr ',' '\n')
        get_container_env "$(echo "$container_info" | jq -r '.ID')"

        log_info "Container found: ID=$container_id, Name=$container_name, Status=$container_status"
        
        # Interpret vars in command
        if [[ -n "${CONTAINER_ENV[POSTGRES_USER]}" ]]; then
            command_to_execute="${CommandToRun/__POSTGRES_USER__/${CONTAINER_ENV[POSTGRES_USER]}}"
        else
            command_to_execute="${CommandToRun}"
        fi
        command_to_execute="${command_to_execute/__FILE_NAME__/${BackupFileName}}"

        log_info "Executing command: docker exec -t $container_id $command_to_execute"

        docker exec -t "$container_id" $command_to_execute
        # Check if backup was successful
        if [ $? -eq 0 ]; then
            log_success "$AppName backup completed successfully"
        else
            log_error "$AppName backup failed"
            return_code=1
        fi

        # Clean up old backup files if backup was successful
        if [ $return_code -eq 0 ]; then
            # Manage with folder(s) mount
            if [[ -n "$container_mounts" && "$container_mounts" == */* ]]; then
                log_info "Checking backup paths: $container_mounts"

                for path in $container_mounts; do
                    if ls "$path" | grep -q "$BackupFolderName"; then
                        delete_old_files "$path/$BackupFolderName" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
                    fi
                done
            # Manage without folder(s) mount
            else
                HostContainerBackupPath="$HostBackupPath/$container_name"
                log_info "No host's mount paths found, copying backup files on host to: $HostContainerBackupPath"
                mkdir -p "$HostContainerBackupPath"
                docker cp "$container_id:/${BackupFileName}" "$HostContainerBackupPath/${BackupFileName}"
                docker exec -t "$container_id" rm /${BackupFileName}
                delete_old_files "$HostContainerBackupPath" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
            fi
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

# Recover execution date
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
log_info "Starting backup process at: $exec_date"

HostBackupPath=/${DOCKER_DATA_DIRECTORY:-data}/docker/docker-backup

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
perform_backup "${APP_CONFIG[@]}"

# Postgres
log_info "Searching for Postgres containers..."
Postgres_containers=$(get_container_info 'postgres' 'contains')
if [ -n "$Postgres_containers" ]; then
    echo "$Postgres_containers" | while IFS= read -r container_info; do
        [ -z "$container_info" ] && continue
        container_name=$(echo "$container_info" | jq -r '.Names')
        log_info "Found Postgres container: $container_name"
        APP_CONFIG=(
            "$container_name"
            'exact'
            "pg_dumpall -U __POSTGRES_USER__ -c --if-exist -f __FILE_NAME__"
            'backups'
            ''
            'postgres_backup.sql'
            '2'
        )
        perform_backup "${APP_CONFIG[@]}"
        echo ""
        echo "---------------"
    done
else
    log_warning "No Postgres containers found"
fi

log_success "Script completed successfully"

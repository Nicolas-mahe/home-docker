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
                rm -f "$file"
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
    local return_code=0

    log_info "Starting $AppName backup process..."

    local containers
    containers=$(get_container_info "$AppName" "$Cpattern")

    if [ -z "$containers" ]; then
        log_warning "$AppName container(s) not found or not running, skipping..."
        return 2
    fi

    # Boucler sans sous-shell
    while IFS= read -r container_info; do
        [ -z "$container_info" ] && continue

        local container_id container_name container_status container_mounts command_to_execute BackupFileName
        container_id=$(echo "$container_info" | jq -r '.ID')
        container_name=$(echo "$container_info" | jq -r '.Names')
        container_status=$(echo "$container_info" | jq -r '.Status')
        container_mounts=$(echo "$container_info" | jq -r '.Mounts' | tr ',' '\n')

        PROCESSED_CONTAINERS+=("$container_name")

        get_container_env "$container_id"

        log_info "Container found: ID=$container_id, Name=$container_name, Status=$container_status"

        BackupFileName="${BackupPrefix}_${exec_date}_${BackupSuffix}"

        if [[ -n "${CONTAINER_ENV[POSTGRES_USER]}" ]]; then
            command_to_execute="${CommandToRun/__POSTGRES_USER__/${CONTAINER_ENV[POSTGRES_USER]}}"
        else
            command_to_execute="$CommandToRun"
        fi
        command_to_execute="${command_to_execute/__FILE_NAME__/${BackupFileName}}"

        log_info "Executing command: docker exec -t $container_id $command_to_execute"

        if docker exec -t "$container_id" $command_to_execute; then
            log_success "$container_name backup completed successfully"
        else
            log_error "$container_name backup failed"
            return_code=1
            continue
        fi

        if [[ -n "$container_mounts" && "$container_mounts" == */* ]]; then
            log_info "Checking backup paths: $container_mounts"
            for path in $container_mounts; do
                if ls "$path" | grep -q "$BackupFolderName"; then
                    delete_old_files "$path/$BackupFolderName" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
                fi
            done
        else
            HostContainerBackupPath="$HostBackupPath/$container_name"
            log_info "No host's mount paths found, copying backup files on host to: $HostContainerBackupPath"
            mkdir -p "$HostContainerBackupPath"
            docker cp "$container_id:/${BackupFileName}" "$HostContainerBackupPath/${BackupFileName}"
            docker exec -t "$container_id" rm "/${BackupFileName}"
            delete_old_files "$HostContainerBackupPath" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
        fi

        echo -e "\n---------------\n"
    done < <(echo "$containers")

    return $return_code
}



#===============================================================================
# INITIALIZATION
#===============================================================================

# Recover execution date
exec_date=$(date "+%Y-%m-%d_%H-%M-%S")
log_info "Starting backup process at: $exec_date"

HostBackupPath=/${DOCKER_DATA_DIRECTORY:-data}/docker/docker-backup

declare -a PROCESSED_CONTAINERS=()

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
APP_CONFIG=(
    "postgres"
    "contains"
    "pg_dumpall -U __POSTGRES_USER__ -c --if-exist -f __FILE_NAME__"
    "backups"
    ""
    "postgres_backup.sql"
    "2"
)
perform_backup "${APP_CONFIG[@]}"

if [ ${#PROCESSED_CONTAINERS[@]} -gt 0 ]; then
    echo ""
    log_success "Containers processed during this run:"
    for cname in "${PROCESSED_CONTAINERS[@]}"; do
        log_success "  - $cname"
    done
else
    log_warning "No containers were processed"
fi

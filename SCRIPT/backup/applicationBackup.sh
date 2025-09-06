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
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }

log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }

log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

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

# Function to perform backup of a container application
# Parameters:
#   $1 - AppName: Name of the application/container
#   $2 - CommandToRun: Backup command to execute in the container
#   $3 - BackupFolderName: Name of the folder containing backups
#   $4 - BackupPrefix: Prefix for backup files (optional)
#   $5 - BackupSuffix: Suffix for backup files (optional)
#   $6 - BackupRetention: Number of backups to retain (default: 2)
# Returns:
#   0 if backup successful, 1 if failed, 2 if container not found
perform_backup() {
    local AppName="$1"
    local CommandToRun="$2"
    local BackupFolderName="$3"
    local BackupPrefix="${4:-}"
    local BackupSuffix="${5:-}"
    local BackupRetention="${6:-2}"
    local return_code=0

    log_info "Starting $AppName backup process..."
    local container_info
    container_info=$(get_container_info "$AppName" endswith)

    if [ -n "$container_info" ]; then
        # Extract container information
        local container_id
        local container_name
        local container_status
        container_id=$(echo "$container_info" | jq -r '.ID')
        container_name=$(echo "$container_info" | jq -r '.Names')
        container_status=$(echo "$container_info" | jq -r '.Status')

        log_info "Container found: ID=$container_id, Name=$container_name, Status=$container_status"
        
        # Execute backup command
        log_info "Initiating $AppName backup process..."
        if docker exec -t "$container_id" $CommandToRun; then
            log_success "$AppName backup completed successfully"
        else
            log_error "$AppName backup failed"
            return_code=1
        fi

        # Clean up old backup files if backup was successful
        if [ $return_code -eq 0 ]; then
            local HostBackupPath
            HostBackupPath=$(echo "$container_info" | jq -r '.Mounts' | tr ',' '\n')
            log_info "Checking backup paths: $HostBackupPath"
            
            for path in $HostBackupPath; do
                if ls "$path" | grep -q "$BackupFolderName"; then
                    delete_old_files "$path/$BackupFolderName" "$BackupPrefix" "$BackupSuffix" "$BackupRetention"
                fi
            done
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
    "gitlab"                # AppName
    "gitlab-backup create"  # CommandToRun
    "backups"              # BackupFolderName
    ""                     # BackupPrefix
    "gitlab_backup.tar"    # BackupSuffix
    "2"                    # BackupRetention
)

# Execute backup with configuration
perform_backup "${APP_CONFIG[@]}"

log_success "Script completed successfully"

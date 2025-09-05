#!/bin/bash

# Color definitions for logs
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

# Generic function to get container information
# Usage:
#   get_container_info <name> [mode]
# mode = exact (default) | startswith | endswith | contains
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
    docker ps -f "name=${pattern}" --format '{{json .}}'
}

# GitLab
container_info=$(get_container_info gitlab)
if [ -n "$container_info" ]; then
    container_id=$(echo "$container_info" | jq -r '.ID')
    container_name=$(echo "$container_info" | jq -r '.Names')
    container_status=$(echo "$container_info" | jq -r '.Status')

    log_info "Container found: ID=$container_id, Name=$container_name, Status=$container_status"
    docker exec -t "$container_id" ls #gitlab-backup create
else
    log_warning "Container not found or not running."
fi

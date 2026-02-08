#!/bin/bash

# Check required argument
if [ -z "$1" ]; then
    echo "Usage: $0 <ip_or_hostname> [port] [user]"
    exit 1
fi

REMOTE_HOST="$1"
REMOTE_PORT="${2:-22}"
REMOTE_USER="${3:-root}"

echo "Pinging $REMOTE_HOST..."

if ping -c 2 -W 2 "$REMOTE_HOST" > /dev/null 2>&1; then
    echo "Ping OK."
    echo "Connecting via SSH to ${REMOTE_USER}@${REMOTE_HOST} (port $REMOTE_PORT)..."
    ssh -p "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST} "shutdown -h 1"
    
    if [ $? -eq 0 ]; then
        echo "Shutdown command sent successfully."
    else
        echo "Error during SSH connection."
    fi
else
    echo "Host unreachable by ping, allready powered off or network issue."
fi

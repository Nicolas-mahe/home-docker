#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="/$(echo "$SCRIPT_DIR" | cut -d'/' -f2)"

# Set VaultWarden VARS
read -r BW_CLIENTID < "$DATA_DIR/docker/docker-secret/vaultwarden/VW_CLIENTID.txt"
read -r BW_CLIENTSECRET < "$DATA_DIR/docker/docker-secret/vaultwarden/VW_CLIENTSECRET.txt"
PASSWORD_FILE="$DATA_DIR/docker/docker-secret/vaultwarden/VW_PASSWORD.txt"
BW="$3/bw" # Path to bitwarden CLI


# # # 1st use (Config)
# # alias bw='/data/script/bw'
# # bw config server https://vaultwarden.${PERSONAL_DOMAIN_NAME}

# # Init connection
# bw logout
# bw login --apikey

# Recover Session's Token
OUTPUT=$($BW unlock --passwordfile "$PASSWORD_FILE")
BW_SESSION=$(echo "$OUTPUT" | grep -oP '(?<=export BW_SESSION=")[^"]+')
if [ -z "$BW_SESSION" ]; then
    echo "Error : Token BW_SESSION not found"
    exit 1
fi
export BW_SESSION="$BW_SESSION"

if [ ! -d "$2/Vaultwarden" ]; then
    mkdir -p "$2/Vaultwarden"
fi

# Export Vault
$BW export --output $2/Vaultwarden/$1.json --format encrypted_json && \
$BW lock
#!/bin/bash

# Set VaultWarden VARS
read -r VW_CLIENTID < ../docker/docker-secret/vaultwarden/VW_CLIENTID.txt
export BW_CLIENTID="$VW_CLIENTID"
read -r VW_CLIENTSECRET < ../docker/docker-secret/vaultwarden/VW_CLIENTSECRET.txt
export BW_CLIENTSECRET="$VW_CLIENTSECRET"
PASSWORD_FILE="../docker/docker-secret/vaultwarden/VW_PASSWORD.txt"
BW="../script/bw"


# # # 1st use (Config)
# # alias bw='/data/script/bw'
# # $BW config server https://vaultwarden.${PERSONAL_DOMAIN_NAME}

# # Init connection
# $BW logout
# $BW login --apikey

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
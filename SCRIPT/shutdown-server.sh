#!/bin/bash

# Vérification argument obligatoire
if [ -z "$1" ]; then
    echo "Usage: $0 <ip_ou_hostname> [port] [user]"
    exit 1
fi

REMOTE_HOST="$1"
REMOTE_PORT="${2:-22}"
REMOTE_USER="${3:-root}"

echo "Test du ping vers $REMOTE_HOST..."

if ping -c 2 -W 2 "$REMOTE_HOST" > /dev/null 2>&1; then
    echo "Ping OK."
    echo "Connexion SSH sur ${REMOTE_USER}@${REMOTE_HOST} (port $REMOTE_PORT)..."
    
    ssh -p "$REMOTE_PORT" -o ConnectTimeout=5 ${REMOTE_USER}@${REMOTE_HOST} "sudo shutdown -h 1"
    
    if [ $? -eq 0 ]; then
        echo "Commande d'extinction envoyée avec succès."
    else
        echo "Erreur lors de la connexion SSH."
    fi
else
    echo "Machine injoignable par ping."
fi

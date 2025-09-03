#!/bin/sh
set -e

TOKEN="${NEXTCLOUD_API_TOKEN}"

if [ -n "$TOKEN" ]; then
  echo "🔧 Configuration du token API..."
  php occ config:app:set serverinfo token --value="$TOKEN"
  echo "✅ Token API configuré."
else
  echo "⚠️ Aucune valeur de token API fournie."
fi

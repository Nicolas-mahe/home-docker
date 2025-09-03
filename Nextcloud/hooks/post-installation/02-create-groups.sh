#!/bin/sh
set -e

ALLOWED_GROUP="${NEXTCLOUD_EXTERNAL_GROUP:-admin}"

# Creer le groupe si il n'existe pas
if ! php occ group:list | grep -q "$ALLOWED_GROUP"; then
  echo "➕ Création du groupe '$ALLOWED_GROUP'..."
  php occ group:add "$ALLOWED_GROUP"
else
  echo "ℹ️ Le groupe '$ALLOWED_GROUP' existe déjà."
fi
echo "✅ Tous les groupes sont configurés."
#!/bin/sh
set -e

ALLOWED_GROUP="${NEXTCLOUD_EXTERNAL_GROUP:-admin}"
ADMIN_USER="${NEXTCLOUD_ADMIN_USER:-admin}"

# Création du groupe s'il n'existe pas
if ! php occ group:list | grep -q "$ALLOWED_GROUP"; then
  echo "➕ Création du groupe '$ALLOWED_GROUP'..."
  php occ group:add "$ALLOWED_GROUP"
else
  echo "ℹ️ Le groupe '$ALLOWED_GROUP' existe déjà."
fi

# Ajout de l'utilisateur admin au(x) groupe(s)
php occ group:adduser "$ALLOWED_GROUP" "$ADMIN_USER"
echo "👤 Ajout de l’utilisateur '$ADMIN_USER' au groupe '$ALLOWED_GROUP'..."

echo "✅ Configuration des groupes terminée."

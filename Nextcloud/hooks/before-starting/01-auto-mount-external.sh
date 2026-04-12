#!/bin/sh
set -e

# Groupe autorisé
ALLOWED_GROUP="${NEXTCLOUD_EXTERNAL_GROUP:-admin}"

# Fonction pour récupérer l'ID d'un montage par son label
get_storage_id() {
  LABEL="$1"
  php occ files_external:list --output=json \
    | php -r '
        $label = "/" . $argv[1];
        $json = json_decode(stream_get_contents(STDIN), true);
        foreach ($json as $mount) {
            if (isset($mount["mount_point"]) && $mount["mount_point"] === $label) {
                echo $mount["mount_id"];
                exit;
            }
        }' "$LABEL"
}
if [ -f /var/www/html/version.php ]; then
  echo "📦 Activation de l’app files_external (si non active)..."
  php occ app:enable files_external || true
  # Parcours tous les sous-dossiers dans /mnt
  for DIR in /mnt/*; do
    if [ -d "$DIR" ]; then
      LABEL=$(basename "$DIR")
      echo "🔍 Traitement du dossier : $LABEL"

      # Vérifie si le stockage existe déjà
      if php occ files_external:list | grep -q "/$LABEL"; then
        echo "ℹ️ Le stockage externe '$LABEL' existe déjà."
      else
        echo "➕ Ajout du stockage externe '$LABEL'..."
        php occ files_external:create "/$LABEL" local null::null -c datadir="$DIR"

        # Récupère l'ID
        STORAGE_ID=$(get_storage_id "$LABEL")
        echo "🔍 L'ID du stockage '$LABEL' est le $STORAGE_ID"

        if [ -n "$STORAGE_ID" ]; then
          echo "👥 Restriction du stockage '$LABEL' (ID=$STORAGE_ID) au groupe '$ALLOWED_GROUP'..."
          php occ files_external:applicable --add-group="$ALLOWED_GROUP" "$STORAGE_ID"
        else
          echo "⚠️ Impossible de récupérer l'ID du stockage '$LABEL'."
        fi
      fi
    fi
  done

  echo "✅ Tous les stockages externes sont configurés."
else
  echo "⚠️ Nextcloud n'est pas encore installé, les stockages externes seront configurés après l'installation."
fi

#!/bin/sh
set -e

echo "📦 Activation de l’app files_external (si non active)..."
php occ app:enable files_external || true

# Parcours tous les sous-dossiers dans /mnt
for DIR in /mnt/*; do
  if [ -d "$DIR" ]; then
    LABEL=$(basename "$DIR")
    echo "🔍 Traitement du dossier : $LABEL"

    # Vérifie si le stockage existe déjà
    if php occ files_external:list | grep -q "$LABEL"; then
      echo "ℹ️ Le stockage externe '$LABEL' existe déjà."
    else
      echo "➕ Ajout du stockage externe '$LABEL'..."
      php occ files_external:create "$LABEL" local null::null -c datadir="$DIR"
    fi
  fi
done

echo "✅ Tous les stockages externes sont configurés."

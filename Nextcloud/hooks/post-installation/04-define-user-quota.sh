#!/bin/sh
set -e

DEFAULT_QUOTA="${NEXTCLOUD_DEFAULT_QUOTA:-10 GB}"

echo "⚙️ Configuration des quotas Nextcloud..."

# Définit le quota par défaut pour les nouveaux utilisateurs
echo "📦 Définition du quota pour les nouveaux utilisateurs par défaut à $DEFAULT_QUOTA..."
php occ config:app:set files default_quota --value="$DEFAULT_QUOTA"

echo "✅ Configuration des quotas terminée."
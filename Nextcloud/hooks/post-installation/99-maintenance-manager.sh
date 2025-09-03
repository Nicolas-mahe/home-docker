#!/bin/sh
set -e

echo "🔧 Définition de la plage de maintenance"
php occ config:system:set maintenance_window_start --type=integer --value=1

echo "🔧 Execution d'une maintenance preventive..."
php occ maintenance:repair --include-expensive

echo "🔧 Ajout des index de base de données manquants..."
php occ db:add-missing-indices

echo "📞 Definition de la région téléphonique par défaut"
php occ config:system:set default_phone_region --value='FR'
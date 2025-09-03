#!/bin/sh
set -e

echo "📦 Activation de l'app oidc_login..."
php occ app:install oidc_login || true
php occ app:enable oidc_login || true

[ -z "$OIDC_PROVIDER_URL" ] && echo "⚠️ OIDC_PROVIDER_URL non définie" && exit 1
[ -z "$OIDC_CLIENT_ID" ] && echo "⚠️ OIDC_CLIENT_ID non définie" && exit 1
[ -z "$OIDC_CLIENT_SECRET" ] && echo "⚠️ OIDC_CLIENT_SECRET non définie" && exit 1
[ -z "$PERSONAL_DOMAIN_NAME" ] && echo "⚠️ PERSONAL_DOMAIN_NAME non définie" && exit 1

export CONFIG_FILE="/var/www/html/config/config.php"

echo "⚙️ Ajout de la configuration OIDC via enable-oidc.php..."
php /docker-entrypoint-hooks.d/post-installation/enable-oidc.php
echo "✅ Configuration OIDC terminée."

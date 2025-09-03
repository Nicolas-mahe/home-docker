#!/bin/sh

# from https://docs.nextcloud.com/server/31/admin_manual/configuration_server/theming.html

set -e

echo "🎨 Configuration du thème Nextcloud via CLI..."

# Variables d'environnement
NEXTCLOUD_SITE_NAME="${NEXTCLOUD_SITE_NAME}"
NEXTCLOUD_SLOGAN="${NEXTCLOUD_SLOGAN}"
NEXTCLOUD_SITE_URL="https://${NEXTCLOUD_TRUSTED_DOMAINS}"
NEXTCLOUD_THEME_COLOR="${NEXTCLOUD_THEME_COLOR}"
NEXTCLOUD_TEXT_COLOR="${NEXTCLOUD_TEXT_COLOR}"
NEXTCLOUD_LOGO_PATH="${NEXTCLOUD_LOGO_PATH}"
NEXTCLOUD_BACKGROUND_PATH="${NEXTCLOUD_BACKGROUND_PATH}"

# Si au moins une variable est définie
if [ -n "$NEXTCLOUD_SITE_NAME" ] || [ -n "$NEXTCLOUD_SLOGAN" ] || [ -n "$NEXTCLOUD_SITE_URL" ] || [ -n "$NEXTCLOUD_THEME_COLOR" ] || [ -n "$NEXTCLOUD_TEXT_COLOR" ] || [ -n "$NEXTCLOUD_LOGO_PATH" ] || [ -n "$NEXTCLOUD_BACKGROUND_PATH" ]; then
  if [ -n "$NEXTCLOUD_SITE_NAME" ]; then
    php occ theming:config name "$NEXTCLOUD_SITE_NAME"
    echo "✅ Nom du site configuré."
  else
    echo "❌ Nom du site non configuré."
  fi

  if [ -n "$NEXTCLOUD_SLOGAN" ]; then
    php occ theming:config slogan "$NEXTCLOUD_SLOGAN"
    echo "✅ Slogan configuré."
  else
    echo "❌ Slogan non configuré."
  fi

  if [ -n "$NEXTCLOUD_SITE_URL" ]; then
    php occ theming:config url "$NEXTCLOUD_SITE_URL"
    echo "✅ URL du site configuré."
  else
    echo "❌ URL du site non configuré."
  fi

  if [ -n "$NEXTCLOUD_THEME_COLOR" ]; then
    php occ theming:config primary_color "$NEXTCLOUD_THEME_COLOR"
    echo "✅ Couleur du thème configurée."
  else
    echo "❌ Couleur du thème non configurée."
  fi

  if [ -n "$NEXTCLOUD_TEXT_COLOR" ]; then
    php occ theming:config color "$NEXTCLOUD_TEXT_COLOR"
    echo "✅ Couleur du texte du thème configurée."
  else
    echo "❌ Couleur du texte du thème non configurée."
  fi

  echo "✅ Désactivation de la personnalisation du thème par les utilisateurs."
  php occ theming:config disable-user-theming yes

  # Nettoyage du cache fait par le prochain script
  # php occ maintenance:repair

  echo "✅ Thème Nextcloud configuré avec succès."
else
  echo "❌ Aucune configuration de thème Nextcloud à appliquer."
fi
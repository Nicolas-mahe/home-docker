# !/bin/bash
# This script is used to trigger a backup of the Mealie application via its API.
# set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SECRET_DATA_DIRECTORY="$SCRIPT_DIR/../../.."

read -r RAID_DATA_DIRECTORY < "$SECRET_DATA_DIRECTORY/docker/docker-secret/global/RAID_DATA_DIRECTORY.txt"
read -r PERSONAL_DOMAIN_NAME < "$SECRET_DATA_DIRECTORY/docker/docker-secret/global/PERSONAL_DOMAIN_NAME.txt"
read -r MEALIE_API_TOKEN < "$SECRET_DATA_DIRECTORY/docker/docker-secret/mealie/MEALIE_API_TOKEN.txt"

MEALIE_API_BACKUP="https://mealie.${PERSONAL_DOMAIN_NAME}/api/admin/backups"

# Get the previous backup file name from the API response
echo "Retrieving backup file name from Mealie API..."
backup_file_name=$(curl -f \
  -H "Authorization: Bearer ${MEALIE_API_TOKEN}" \
  "${MEALIE_API_BACKUP}" | jq -er '.imports[0].name')
echo ""

# Delete previous backup from mealie instance
echo "Deleting backup from Mealie instance..."
curl -f -X DELETE \
  -H "Authorization: Bearer ${MEALIE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${MEALIE_API_BACKUP}/${backup_file_name}"

# Run New Backup
echo "Triggering Mealie backup via API..."
curl -f -X POST \
  -H "Authorization: Bearer ${MEALIE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  ${MEALIE_API_BACKUP}

# # Get the backup file name from the API response
# echo "Retrieving backup file name from Mealie API..."
# backup_file_name=$(curl -f \
#   -H "Authorization: Bearer ${MEALIE_API_TOKEN}" \
#   "${MEALIE_API_BACKUP}" | jq -er '.imports[0].name')

# # Download the backup file to the specified directory
# mealie_backup_dir="/${RAID_DATA_DIRECTORY}/backup/Apps-conf/Mealie"
# mkdir -p "$mealie_backup_dir"
# echo "Downloading backup file ${backup_file_name} to ${mealie_backup_dir}..."
# curl -s \
#   -H "Authorization: Bearer ${MEALIE_API_TOKEN}" \
#   "${MEALIE_API_BACKUP}/${backup_file_name}" -o "${mealie_backup_dir}/${backup_file_name}"
# chown docker:maison "${mealie_backup_dir}/${backup_file_name}"
# chmod -R 777 "${mealie_backup_dir}"
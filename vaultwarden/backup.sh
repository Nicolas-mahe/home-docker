# !/bin/bash
# This script is used to trigger a backup of the Vaultwarden application via docker & buitlin commands.

/bin/docker exec -t vaultwarden /vaultwarden backup

# purge old backups older than 7 days
/bin/docker exec -t vaultwarden sh -c "cd /data && find . -type f -name 'db_*_*.sqlite3' ! -mtime -7 -exec rm {} +"

/bin/docker exec -t vaultwarden sh -c "cd /data && ls -al db_*_*.sqlite3"
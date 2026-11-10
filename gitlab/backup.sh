# !/bin/bash
# This script is used to trigger a backup of the GitLab application via docker & gitlab commands.

Backup_dir="/var/opt/gitlab/backups"

/bin/docker exec gitlab sh -c "if ls $Backup_dir | wc -l > 0; then rm -f $Backup_dir/* ; fi"

/bin/docker exec -t gitlab gitlab-backup create CRON=1
/bin/docker exec -t gitlab gitlab-ctl backup-etc --backup-path $Backup_dir CRON=1
/bin/docker exec -t gitlab chmod -R 677 $Backup_dir
# !/bin/bash
# This script is used to trigger a backup of the GitLab application via docker & gitlab commands.

/bin/docker exec -t gitlab gitlab-backup create CRON=1
/bin/docker exec -t gitlab gitlab-ctl backup-etc --backup-path /var/opt/gitlab/backups CRON=1
/bin/docker exec -t gitlab chmod -R 677 /var/opt/gitlab/backups/
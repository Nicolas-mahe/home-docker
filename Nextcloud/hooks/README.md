# Requirements

All `files.sh` scripts must be executable. You can set the executable permission using the following command:

```bash
cd /$DATA_DIRECTORY/repos/home-docker/Nextcloud
find . -type f -name "*.sh" -exec chmod +x {} \;
```

# Test the hooks

```bash
docker compose -f /$DATA_DIRECTORY/repos/home-docker/Nextcloud/compose.yaml down
sudo rm -r /$RAID_DIRECTORY/nextcloud/*
sudo rm -r /$DATA_DIRECTORY/docker/docker-$DATA_DIRECTORY/nextcloud
docker volume rm nextcloud-postgres nextcloud-redis
docker compose -f /$DATA_DIRECTORY/repos/home-docker/Nextcloud/compose.yaml up -d
```
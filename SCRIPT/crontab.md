# List on crontab command
## Shutdown Games server
Checks whether the game server host is reachable and the `minecraft-atm` container is running. If so, it notifies players, saves the world, starts a backup, and checks the container logs every 15 seconds until the backup completes. It then shuts down the host. If the container is not running, it reports that and still shuts down the host.
```bash
if /bin/ping ${PERSONAL_NETWORK}.3 -c 1 2>/dev/null; then /bin/ssh -p ${PERSONAL_SSH_PORT} root@${PERSONAL_NETWORK}.3 "if docker inspect -f '{{.State.Running}}' minecraft-atm 2>/dev/null | grep -qx true; then backup_start=\$(date +%s); docker exec -u 1000 minecraft-atm bash -c 'mc-send-to-console msg @a Extinction dans 5 minutes ; mc-send-to-console save-all ; mc-send-to-console simplebackups backup start'; while docker inspect -f '{{.State.Running}}' minecraft-atm 2>/dev/null | grep -qx true && ! docker logs --since \"\$backup_start\" minecraft-atm 2>&1 | grep -Eq 'Backup completed in [^ ]+min \([^)]*\)'; do sleep 15; done; else echo 'Minecraft not running'; fi; shutdown 1"; fi
```

## Shutodwn AI server
Checks whether the AI server host is reachable and, if it is, connects over SSH to shut it down.
```bash
if /bin/ping ${PERSONAL_NETWORK}.4 -c 1; then /bin/ssh -p ${PERSONAL_SSH_PORT} root@${PERSONAL_NETWORK}.4 "shutdown 1"; fi
```
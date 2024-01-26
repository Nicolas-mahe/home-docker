# Docker Help 
## Minecraft
` docker run -e MOTD="Server Moddé Perso" -e EULA=TRUE -e VERSION=1.18.2 -d -v Minecraft_perso:/data -p 8080:25565 --restart always --name Minecraft-1.18.2 itzg/minecraft-server:2022.14.0 `

mods:
` docker run -d -v Minecraft_mod:/data -e MOTD="RaBByT Season v1" -e TYPE=FORGE -e VERSION=1.18.2 -e FORGE_VERSION=40.1.60 -e MEMORY="" -e JVM_XX_OPTS="-XX:MaxRAMPercentage=95" -m 13056M -e MAX_PLAYERS=10 -e SPAWN_PROTECTION=0 -e VIEW_DISTANCE=12 -e SIMULATION_DISTANCE=12 -e MAX_BUILD_HEIGHT=512 -e ENABLE_WHITELIST=TRUE -p 26666:25565 --restart unless-stopped --name Minecraft_Modde -e EULA=TRUE itzg/minecraft-server:2022.14.0 `
### Be op
` docker exec Minecraft_Modde mc-send-to-console op RaBByT_Tv `
/gamerule keepinventory true
/gamerule playersSleepingPercentage 1


## Enter in docker
` docker exec -it <name> /bin/bash `


## Ansible

apt-get update && \
    apt upgrade -y && \
    apt -y install software-properties-common && \
    apt install -y python3-pip && \
    apt-add-repository --yes --update ppa:ansible/ansible && \
    apt install -y ansible && \
    pip install requests-credssp && \
    apt install libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake gcc -y
## Docker-compose
`docker compose -f Ansible-perso//Portainer/docker-compose.yml up -d --force-recreate --remove-orphans`
`docker compose -f Ansible-perso/Portainer/agent/docker-compose.yml up -d --force-recreate --remove-orphans`

## Authelia
to generate a new password:
`docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'CHANGEME'`

## Fail2Ban
`fail2ban-client status`
`fail2ban-client set [nom du jail] unbanip [IP concerné]`
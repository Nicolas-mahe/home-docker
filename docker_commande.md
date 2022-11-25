# Docker Help 
## Minecraft
` docker run -e MOTD="Server Moddé Perso" -e EULA=TRUE -e VERSION=1.18.2 -d -v Minecraft_perso:/data -p 8080:25565 --restart always --name Minecraft-1.18.2 itzg/minecraft-server:2022.14.0 `

mods:
` docker run -d -v Minecraft_mod:/data -e MOTD="Serveur Minecraft Moddé par RaBByT_Tv" -e TYPE=FORGE -e VERSION=1.18.2 -e FORGE_VERSION=40.1.60 -e MEMORY="" -e JVM_XX_OPTS="-XX:MaxRAMPercentage=75" -m 8196M -e MAX_PLAYERS=10 -e SPAWN_PROTECTION=0 -e VIEW_DISTANCE=6 -e SIMULATION_DISTANCE=8 -e MAX_BUILD_HEIGHT=1024 -e ENABLE_WHITELIST=TRUE -p 26666:25565 --restart always --name Minecraft_Modde -e EULA=TRUE itzg/minecraft-server:2022.14.0 `
### Be op
` docker exec Minecraft_Modde mc-send-to-console op RaBByT_Tv `
/gamerule keepinventory true
/gamerule playersSleepingPercentage 1


## Entrer in docker
` docker exec -it <name> /bin/bash `
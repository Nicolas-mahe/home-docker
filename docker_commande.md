# Docker Help 
## Minecraft
`docker run -e EULA=TRUE -e VERSION=1.19.2 -d -v Minecraft:/data -p 26666:25565 --restart always --name Minecraft-1.19.2 itzg/minecraft-server`

## Entrer in docker
`docker exec -it <name> /bin/bash`
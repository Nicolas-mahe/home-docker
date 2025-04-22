#!/bin/sh

# Config
Container_Name_to_Monitor=minecraft-server
Container_Name_to_Reboot=minecraft-tunnel

# Récupère la sortie de la commande 'rcon-cli list'
PLAYERS_LIST=$(docker exec "$Container_Name_to_Monitor" rcon-cli list)
NB_PLAYERS=$(echo "$PLAYERS_LIST" | sed -n 's/^There are \([0-9]\+\) of a max of [0-9]\+ players online.*$/\1/p')
echo "Nombre de joueurs : $NB_PLAYERS"


if [ "$NB_PLAYERS" -eq 0 ]; then
    echo "Aucun joueur connecté, redémarrage du tunnel..."
    docker restart "$Container_Name_to_Reboot"
else
    echo "$NB_PLAYERS joueur(s) connecté(s). Pas de redémarrage."
fi

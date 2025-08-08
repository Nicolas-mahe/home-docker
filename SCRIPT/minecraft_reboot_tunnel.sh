#!/bin/sh

# Config
Container_Name_to_Monitor=minecraft-server
Container_Name_to_Reboot=minecraft-tunnel

# check the container is running and is started
if [ "$(docker inspect -f '{{.State.Running}}' "$Container_Name_to_Monitor" 2>/dev/null)" = "false" ]; then
    echo "Le conteneur $Container_Name_to_Monitor n'est pas en cours d'exécution."
    NB_PLAYERS=0
else
    # Récupère la sortie de la commande 'rcon-cli list'
    PLAYERS_LIST=$(docker exec "$Container_Name_to_Monitor" rcon-cli list)
    NB_PLAYERS=$(echo "$PLAYERS_LIST" | sed -n 's/^There are \([0-9]\+\) of a max of [0-9]\+ players online.*$/\1/p')
    echo "Nombre de joueurs : $NB_PLAYERS"
fi

if [ "$NB_PLAYERS" -eq 0 ]; then
    echo "Reboot $Container_Name_to_Reboot..."
    docker restart "$Container_Name_to_Reboot"
else
    echo "$NB_PLAYERS joueur(s) connecté(s). Pas de redémarrage."
fi

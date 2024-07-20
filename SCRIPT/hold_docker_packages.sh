#!/bin/bash

# Lister tous les paquets installés contenant 'docker'
docker_packages=$(apt list --installed 2>/dev/null | grep docker | cut -d/ -f1)

# Ajouter containerd.io à la liste des paquets
docker_packages="$docker_packages containerd.io"

# Marquer chaque paquet Docker et containerd.io comme étant retenu
for pkg in $docker_packages; do
    echo "Holding $pkg"
    sudo apt-mark hold $pkg
    # sudo apt-mark unhold $pkg
done

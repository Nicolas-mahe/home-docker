#!/bin/bash

docker_up=0

while [ $docker_up -eq 0 ]; do
    if ping -c 1 docker &> /dev/null; then
        ssh docker@docker "docker restart duplicati nextcloud grafana"
        docker_up=1
    else
        sleep 20
    fi
done

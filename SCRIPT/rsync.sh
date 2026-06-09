#!/bin/bash
if [ -z /mnt/f ]; then
    echo "Error: /mnt/f is not mounted. Please mount it before running this script."
    exit 1
else
    echo "Starting rsync Share..."
    sharePathList=(commun photos videos films musiques)
    for sharePath in "${sharePathList[@]}"
    do
        echo "Syncing $sharePath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/hdd/partage/$sharePath/" "/mnt/e/$sharePath"
    done

    echo "Starting rsync Backup..."
    pathBackupsList=(backup iso)
    for backupPath in "${pathBackupsList[@]}"
    do
        echo "Syncing $backupPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/hdd/$backupPath/" "/mnt/e/$backupPath"
    done

    echo "Starting rsync docker..."
    pathDockerList=(backup data secret)
    for dockerPath in "${pathDockerList[@]}"
    do
        echo "Syncing $dockerPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/ssd/docker/docker-$dockerPath/" "/mnt/e/docker-$dockerPath"
    done

    echo "Starting rsync Git..."
    pathGitList=(repos)
    for GitPath in "${pathGitList[@]}"
    do
        echo "Syncing $GitPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/ssd/$GitPath/" "/mnt/e/$GitPath"
    done

    echo "Finish rsync !"
fi
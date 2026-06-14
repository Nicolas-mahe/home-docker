#!/bin/bash
DestPath='/mnt/f'
if [ -z '$DestPath/System Volume Information' ]; then
    echo "Error: $DestPath is not mounted. Please mount it before running this script."
    exit 1
else
    echo "Starting rsync Share..."
    sharePathList="commun photos videos films musiques"
    for sharePath in $sharePathList
    do
        echo "Syncing $sharePath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/hdd/partage/$sharePath/" "$DestPath/$sharePath"
    done

    echo "Starting rsync Backup..."
    pathBackupsList="backup iso"
    for backupPath in $pathBackupsList
    do
        echo "Syncing $backupPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/hdd/$backupPath/" "$DestPath/$backupPath"
    done

    echo "Starting rsync docker..."
    pathDockerList="backup data secret"
    for dockerPath in $pathDockerList
    do
        echo "Syncing $dockerPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/ssd/docker/docker-$dockerPath/" "$DestPath/docker-$dockerPath"
    done

    echo "Starting rsync Git..."
    pathGitList="repos"
    for GitPath in $pathGitList
    do
        echo "Syncing $GitPath..."
        rsync -avz --delete -e "ssh -p 6336 -i ~/.ssh/rabbyt_rsa" "docker@192.168.0.2:/mnt/ssd/$GitPath/" "$DestPath/$GitPath"
    done

    echo "Finish rsync !"
fi

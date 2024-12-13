#!/bin/bash
BACKUP_NAME=docker-backup-$(date +'%Y-%m-%d_%I-%M').tar
ROOT_FOLDER=/opt/docker-homelab

docker stop "$(docker ps -a -q)"

rsync -r $ROOT_FOLDER/configs /mnt/alex/Network/backups/docker &>> /media/alex/Network/logs/rsync-docker-backups.log
rsync -r $ROOT_FOLDER/data /media/alex/Network/backups/scripts &>> /media/alex/Network/logs/rsync-scripts-backups.log

tar --exclude='Cache/' --exclude='Transcode/' -czvf /tmp/"$BACKUP_NAME" /home/alex/docker/configs &>> /media/alex/Network/logs/tar-docker-backups.log
cp /tmp/"$BACKUP_NAME" /media/alex/Network/backups/tar/docker/"$BACKUP_NAME"

docker start "$(docker ps -a -q)"

rm /tmp/"$BACKUP_NAME"
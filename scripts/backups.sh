#!/bin/bash
BACKUP_NAME=docker-backup-$(date +'%Y-%m-%d_%I-%M').tar

docker stop "$(docker ps -a -q)"

rsync -r /home/alex/docker/ /media/alex/Network/backups/docker &>> /media/alex/Network/logs/rsync-docker-backups.log
rsync -r /home/alex/bin/ /media/alex/Network/backups/scripts &>> /media/alex/Network/logs/rsync-scripts-backups.log

tar --exclude='Cache/' --exclude='Transcode/' -czvf /tmp/"$BACKUP_NAME" /home/alex/docker/configs &>> /media/alex/Network/logs/tar-docker-backups.log
cp /tmp/"$BACKUP_NAME" /media/alex/Network/backups/tar/docker/"$BACKUP_NAME"

docker start "$(docker ps -a -q)"

rm /tmp/"$BACKUP_NAME"
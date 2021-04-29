#!/bin/sh

## THIS SCRIPT CREATES A NEW CONTAINER FROM THE LATEST IMAGE FOR CRASHPLAN-PRO.
## VOLUMES ARE ALREADY EXISITING / CREATED FOR PERSISTENT DATA (i.e. machine config)
## B. Uwalaka - 19/04/2021

## NOTES:
## 19/04/2021 - VNC_PASSWORD env variable no longer used.
## The .vncpass_clear file has the clear text password for VNC and is copied to the root of the config volume.
## During the container startup, content of the file is obfuscated and moved to .vncpass

printf "\n\n Stop the container....\n\n"
docker stop crashplan-pro-1

printf "\n Delete the container....\n\n"
docker rm crashplan-pro-1

printf "\n Create the volumes for persistent data (if already existing no changes are made)\n\n"
docker volume create crashplan-config
docker volume create crashplan-storage

CPCFGVOL=$(docker volume inspect crashplan-config -f {{.Mountpoint}})

printf "\n Copying .vncpass_clear to persistent config volume..\n\n"
if [ -n "$CPCFGVOL" ]
then
    printf "\nVolume path for config = $CPCFGVOL\n\n"
    cp --no-preserve=all .vncpass_clear $CPCFGVOL
else
    printf "\nERROR - Path to persistent volume not found. Exiting script.\n\n"
    exit 1
fi

printf "\n Create new cotainer from latest image and mount persistent data volumes...\n\n"
docker create \
    --name crashplan-pro-1 \
    --hostname QNAPCPFSB \
    -p 32768:5800 -p 32769:5900 \
    -e TZ=Europe/London -e KEEP_APP_RUNNING=1 \
    -v /share/Download:/qnapnas/Download:rw \
    -v /share/Multimedia:/qnapnas/Multimedia:rw \
    -v /share/Public:/qnapnas/Public:rw \
    --mount type=volume,source=crashplan-config,target=/config \
    --mount type=volume,source=crashplan-storage,target=/storage \
    jlesage/crashplan-pro:latest

printf "\n Show current images and containers....\n\n"
docker images
printf "\n\n"
docker ps -a

printf "\n\n#### Now launch Container Station, make your final settings\n\n  AUTO START ON, CPU LIMIT 80\n\n"
printf " Uncheck the \"Please restart the container to apply these settings\" option, apply your changes and Start the container.\n\n"

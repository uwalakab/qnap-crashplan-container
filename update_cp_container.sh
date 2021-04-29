#!/bin/sh
## https://github.com/uwalakab/qnap-crashplan-container-update

## THIS SCRIPT CREATES A NEW CONTAINER FROM THE LATEST IMAGE FOR CRASHPLAN-PRO.
## VOLUMES ARE ALREADY EXISITING / CREATED FOR PERSISTENT DATA (i.e. machine config)
## B. Uwalaka - 19/04/2021

## UPDATE NOTES:
## 19/04/2021 - VNC_PASSWORD env variable no longer used.
## The .vncpass_clear file has the clear text password for VNC and is copied to the root of the config volume.
## During the container startup, content of the file is obfuscated and moved to .vncpass

## 29/04/2021 - Docker never deletes / overwrites an updated/latest image. Added image purging.
## Added error checking function for container stop and removal

## Function error_check will only pass out the message in $1 to console if the exit code is not ZERO
function error_check()
{
if [ $? -ne 0 ]
then
    printf "\n\nERROR - $1 - \nExiting script.\n\n"
    exit 1
fi
}

printf "\n\n Stop the container....\n\n"
docker stop crashplan-pro-1
error_check "Problem encountered stopping the container"

printf "\n Delete the container....\n\n"
docker rm crashplan-pro-1
error_check "Problem encountered deleting the container"

printf "\n Create the volumes for persistent data (if already existing no changes are made)\n\n"
docker volume create crashplan-config
error_check "Problem encountered creating config persisent volume"

docker volume create crashplan-storage
error_check "Problem encountered creating storage presistent volume"

CPCFGVOL=$(docker volume inspect crashplan-config -f {{.Mountpoint}})

printf "\n Copying .vncpass_clear to persistent config volume..\n\n"
if [ -n "$CPCFGVOL" ]
then
    printf "\nVolume path for config = $CPCFGVOL\n\n"
    cp --no-preserve=all .vncpass_clear $CPCFGVOL
    #######  CODE CHANE TO GO HERE ####################################
else
    printf "\nERROR - Path to persistent volume not found. Exiting script.\n\n"
    exit 1
fi

printf "\n Create new container from latest image and mount persistent data volumes...\n\n"
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

error_check "Problem encountered creating local image"

printf "\n Pruning old images......\n\n"
docker image prune -f
error_check "Problem encountered pruning old images"

printf "\n Show current images and containers....\n\nIMAGES\n"
docker images
printf "\n\nCONTAINERS\n"
docker ps -a

printf "\n\n#### Now launch Container Station, make your final settings\n\n  AUTO START ON, CPU LIMIT 80\n\n"
printf " Uncheck the \"Please restart the container to apply these settings\" option, apply your changes and Start the container.\n\n"

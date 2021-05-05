#!/bin/sh
## https://github.com/uwalakab/qnap-crashplan-container-update

## THIS SCRIPT CREATES A NEW CONTAINER FROM THE LATEST JLESAGE IMAGE FOR CRASHPLAN-PRO.
## VOLUMES ARE ALREADY EXISITING / CREATED FOR PERSISTENT DATA (i.e. machine config)
## B. Uwalaka - 19/04/2021

## UPDATE NOTES:
## 19/04/2021 - VNC_PASSWORD env variable no longer used. It is now prompted for.
## The .vncpass_clear file has the clear text password for VNC and is copied to the root of the config volume.
## During the container startup, content of the file is obfuscated and moved to .vncpass

## Function error_check will only pass out the message in $1 to console if the exit code is not ZERO
function error_check()
{
EXITCODE=$?
if [ $DOERRCHK -eq 1 ]
then
    if [ $EXITCODE -ne 0 ]
    then
        printf "\n\n---- ERROR - Problem encountered $1 - Exiting script.\n\n"
        exit 1
    fi
fi
}

## Get path for the crashplan-config persistent volume
CPCFGVOL=$(docker volume inspect crashplan-config -f {{.Mountpoint}})

## -- ADD SCRIPT TO BACKUP PERSISTENT VOLUME DATA HERE --


## If any paremeter is sent with script then all error checking is ignored.
if [ $# -eq 0 ]; then DOERRCHK=1; else DOERRCHK=0; fi


printf "\n\n Stop the container....\n\n"
docker stop crashplan-pro-1
error_check "stopping the container"

printf "\n Delete the container....\n\n"
docker rm crashplan-pro-1
error_check "deleting the container"

printf "\n Create the volumes for persistent data (if already existing no changes are made)\n\n"
docker volume create crashplan-config
error_check "creating crashplan-config persisent volume"

docker volume create crashplan-storage
error_check "creating storage presistent volume"

if [ -n "$CPCFGVOL" ]
then
    printf "\nVolume path for config = $CPCFGVOL\n\n"
    
    if [ ! -f $CPCFGVOL/.vncpass ]
    then
        printf "\nVNC password needs to be set.\n\n"
        read -p "Enter New Password (not hidden): " VNCPWD
        echo $VNCPWD > $CPCFGVOL/.vncpass_clear
    else
        printf "\nVNC password already set.\n\n"
    fi
else
    printf "\n---- ERROR - Path to persistent volume not found - Exiting script.\n\n"
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

error_check "creating local image"

printf "\n Pruning old images......\n\n"
docker image prune -f
error_check "pruning old images"

printf "\n Show current images and containers....\n\nIMAGES\n------\n"
docker images
printf "\n\nCONTAINERS\n----------\n"
docker ps -a

printf "\n\n#### Now launch Container Station, make your final settings\n\n  AUTO START ON, CPU LIMIT 80\n\n"
printf " Uncheck the \"Please restart the container to apply these settings\" option, apply your changes and Start the container.\n\n"

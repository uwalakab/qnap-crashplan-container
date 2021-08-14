#!/bin/sh
## https://github.com/uwalakab/qnap-crashplan-container-update

## THIS SCRIPT CREATES A NEW CONTAINER FROM THE LATEST JLESAGE IMAGE FOR CRASHPLAN-PRO.
## VOLUMES ARE ALREADY EXISITING / CREATED FOR PERSISTENT DATA (i.e. machine config)
## B. Uwalaka - 19/04/2021

## UPDATE NOTES:
## 19/04/2021 - VNC_PASSWORD env variable no longer used. It is now prompted for.
## The .vncpass_clear file has the clear text password for VNC and is copied to the root of the config volume.
## During the container start-up, content of the file is obfuscated and moved to .vncpass

## 06/06/2021 - Name of the container and image is set by variables in the script

## 21/07/2021 - Added check to ensure QNAP "admin" is the user, backup of persistent data using rsync command and map the homes share from QNAP

## Check user is "admin" that is running this script
if [ "$USER" != "admin" ]; then printf "\n---- ERROR - This script must be run as admin.\n\n---- Use sudo -i if you are in the administrators group.\n\n"; exit 1; fi

## Set the variables for the script
## Get path for the crashplan-config persistent volume
CPCFGVOL=$(docker volume inspect crashplan-config -f {{.Mountpoint}})
BACKUPDIR="$PWD/backup-of-config-volume"
## Set container name
CTNRNAME=cppro
## Set container image
CTNRIMAGE=jlesage/crashplan-pro:latest

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


## Check persistent volume and backup directories exist. If they do not then exit the script
if [ ! -d "$CPCFGVOL" ]
then
    printf "\n---- ERROR - Path to persistent volume directory not found - Exiting script.\n\n"
    exit 1
elif [ ! -d "$BACKUPDIR" ]
then
    printf "\n---- ERROR - Path to backup directory not found - Exiting script.\n---- PATH should be $BACKUPDIR\n\n"
    exit 1
fi


## If any parameter is sent with script then all error checking is ignored.
if [ $# -eq 0 ]; then DOERRCHK=1; else DOERRCHK=0; fi


printf "\n\n Stop the container....\n\n"
docker stop $CTNRNAME
error_check "stopping the container"

printf "\n\n Backup persistent data....\n\n"
rsync --delete-after -av "$CPCFGVOL/" "$BACKUPDIR/"
error_check "backing up persistent data"

printf "\n Delete the container....\n\n"
docker rm $CTNRNAME
error_check "deleting the container"

printf "\n Create the volumes for persistent data (if already existing no changes are made)\n\n"
docker volume create crashplan-config
error_check "creating crashplan-config persistent volume"

docker volume create crashplan-storage
error_check "creating crashplan-storage persistent volume"

## We know persistent volume exists from check earlier in the code
printf "\nVolume path for config = $CPCFGVOL\n\n"

## Check there is a password already set for VNC
if [ -f $CPCFGVOL/.vncpass ]
then
    printf "\nVNC password already set.\n\n"
else
    printf "\nVNC password needs to be set.\n\n"
    read -p "Enter New Password (not hidden): " VNCPWD
    echo $VNCPWD > $CPCFGVOL/.vncpass_clear
fi

## printf "\n Removing the local image"
## docker rmi $CTNRIMAGE
## error_check "removing local image"

printf "\n Create new container from latest image and mount persistent data volumes...\n\n"
docker create \
    --pull always \
    --name $CTNRNAME \
    --hostname QNAPCPFSB \
    -p 32768:5800 -p 32769:5900 \
    -e TZ=Europe/London -e KEEP_APP_RUNNING=1 -e USER_ID=0 -e GROUP_ID=0 \
    -v /share/Download:/qnapnas/Download:rw \
    -v /share/Multimedia:/qnapnas/Multimedia:rw \
    -v /share/Public:/qnapnas/Public:rw \
    -v /share/homes:/qnapnas/homes:rw \
    --mount type=volume,source=crashplan-config,target=/config \
    --mount type=volume,source=crashplan-storage,target=/storage \
    $CTNRIMAGE

error_check "creating local image"

printf "\n Pruning old images......\n\n"
docker image prune -f
error_check "pruning old images"

printf "\n Show current images and containers....\n\nIMAGES\n------\n"
docker images
printf "\nCONTAINERS\n----------\n"
docker ps -a

printf "\n\n#### Now launch Container Station, make your final settings\n\n  AUTO START ON, CPU LIMIT 80\n\n"
printf " Uncheck the \"Please restart the container to apply these settings\" option, apply your changes and Start the container.\n\n"

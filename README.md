# QNAP Crashplan container update script
Script for updating Crashplan Pro container on the QNAP NAS
Using the jlesage/crashplan-pro docker image on the QNAP NAS system running Container Station is a very effective (but un-supported) way of being able to backup data from shares on your NAS drive.

Once you have followed the instructions on configuring the jlesage/crashplan-pro docker image on github, this script assists in maintaining the local docker image and container used. You only need to provide a few settings in the QNAP Container Station GUI for the docker image.

The script has a mode where you just pass any paremter if you want to by-pass the error checking that it makes at certain stages in the script.

Example: Below will by-pass error checking at the various stages of the script.
```
./update_cp_container.sh blah
```
Whereas this will run the error checking.
```
./update_cp_container.sh
```

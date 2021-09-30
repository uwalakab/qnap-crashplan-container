# QNAP Crashplan container update script
Script for updating Crashplan Pro container on the QNAP NAS
Using the jlesage/crashplan-pro docker image on the QNAP NAS system running Container Station is a very effective (but un-supported) way of being able to backup data from shares on your NAS drive.

This script is created to automate and simplify the maintaining of the image and container used.
You only need to gave minor interaction with the QNAP Container Station GUI.

The script has a mode where you just pass any paremter if you want to by-pass the error checking that it makes at certain stages in the script.

Example: Below will by-pass error checking at the various stages of the script.
```
./update_cp_container.sh blah
```
Whereas this will run the error checking.
```
./update_cp_container.sh
```

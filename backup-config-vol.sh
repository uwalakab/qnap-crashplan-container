# REFERENCE INFO: Backup the persistent data on the config volume
# Use rsync to perform a differential mirror backup of files (only copy the files that have changed, and delete those that are no longer present in the source).

# PWD = /share/homes/admin/crashplan-stuff (Need to use a user ID that is a sudoer and use the "sudo -i" command to access this PWD)

#!/bin/sh

rsync --delete-after -av ./config-volume/ ./backup-of-config-volume/

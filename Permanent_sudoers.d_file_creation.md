To make sudoers changes permanent on a QNAP TS-253, you must use a startup script because QTS recreates the /usr/etc/sudoers.d directory and the /etc/sudoers file from a RAM image during every boot. 

## Using `autorun.sh` (Recommended)
This is the standard way to ensure your custom sudoers configuration is reapplied after every restart.  
Enable Autorun: In the QTS web interface, go to...  
  
`Control Panel > Hardware and tick "Run user defined processes during startup".`  
  
Mount the Config Partition: SSH into your NAS as admin and mount the special configuration partition where autorun.sh resides. The exact command varies by model, but for Intel-based units like the TS-253, it is typically:
```
bash
# Mount the config partition (example for many QNAP models)
mount $(/sbin/hal_app --get_boot_pd port_id=0)6 /tmp/config
```
_(Use code with caution.)_

Create/Edit the Script: Create or edit /tmp/config/autorun.sh to include a line that injects your user into the sudoers directory:
```
bash

#!/bin/sh
# Re-create the sudoers.d entry file on boot
if [ ! -d /usr/etc/sudoers.d ] ; then mkdir /usr/etc/sudoers.d; fi;
echo "YourUsername ALL=(ALL) ALL" > /usr/etc/sudoers.d/YourUsername
```
_(Use code with caution.)_

Set Permissions & Unmount:
```
bash
chmod +x /tmp/config/autorun.sh
umount /tmp/config
```

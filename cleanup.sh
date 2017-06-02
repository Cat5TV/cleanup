#!/bin/bash

# This script checks a specified folder for disk usage on its device. If it is higher than the
# set threshold it deletes the oldest subfolder in the folder, and loops until it has deleted
# enough files in that folder to then be within the threshold. It stops once the threshold is
# satisfied and then runs your backup (if you enter the commands where specified).

# It goes without saying, if misconfigured, this script can be highly dangerous
# Set testmode to 0 only when you are 100% confident your config is working correctly
# It should show you the folder it will remove, and that should be the oldest folder

# User Settings
threshold=90 # How much disk usage % before cleanup
folder='/home/cat5tv_main/backup/daily' # The folder which contains the subfolders
device='/dev/mapper/backup' # The device on which the folder resides
mode='file' # file | subfolder - which do you want to remove?
testmode=1 # 0=destroy! 1=test only, do not remove anything

echo "Cleanup v1.0"
echo "By Robbie Ferguson"
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

echo Folder: $folder

deviceesc=$(echo $device | sed 's/\//\\\//g')

echo Device: $device

diskusage=$(/bin/df -hl | /usr/bin/awk '/^'"$deviceesc"'/ { sum+=$5 } END { print sum }')

echo Usage:  $diskusage%

if [ "$diskusage" -lt "$threshold" ]; then echo Less than $threshold% usage. No cleanup needed.; exit; fi;

while [ "$diskusage" -ge "$threshold" ]; do

  if [ "$testmode" -eq "1" ]; then

    if [ "$mode" = "file" ]; then
      echo Test mode. Would remove: $(ls -A1t $folder/* | tail -n 1)
    elif [ "$mode" = "subfolder" ]; then
      echo Test mode. Would remove: $(ls -dA1t $folder/*/ | tail -n 1)
    else
      echo Invalid mode specified in config.
    fi

    break

  elif [ "$testmode" -eq "0" ]; then

    if [ "$mode" = "file" ]; then
      /bin/ls -A1t $folder/* | /usr/bin/tail -n 1 | /usr/bin/xargs --verbose -d '\n' /bin/rm -f
    elif [ "$mode" = "subfolder" ]; then
      /bin/ls -dA1t $folder/*/ | /usr/bin/tail -n 1 | /usr/bin/xargs --verbose -d '\n' /bin/rm -rf
    else
      echo Invalid mode specified in config.
    fi

    /bin/sync
    diskusage=$(/bin/df -hl | /usr/bin/awk '/^'"$deviceesc"'/ { sum+=$5 } END { print sum }')

  fi

done

echo Done. Disk usage is now at $diskusage%.

##########################
# INSERT BACKUP/RSYNC HERE


# END OF BACKUP/RSYNC
##########################

/bin/sync

fi
echo ""

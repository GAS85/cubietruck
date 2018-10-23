#!/bin/bash

# By Georgiy Sitnikov.
# AS-IS without any warranty

#Your share folder
SAMBA=/home/USER/share/Video

#Aria2 WEB Config
ARIA2WebUIConfig=/var/www/webui-aria2-master/configuration.js

#Aria2 Configuration file
ARIA2Config=/etc/aria2.conf

#Do you want to adjust ARIA2 WebUI true or false
ARIA2=true

#Do you want to create information file with name "free_XXXGB_SALT.md" in your share
FILE=true

#Do you want to do Aria 2 old files clean up?
CLEAN=true
#How old files should be before clean up in days?
Older=20

#
### DO NOT TOUCH AFTER THIS LINE ###
#

#Check if ARIA2 config is presented
if [ "$ARIA2" = true ]; then

	if [ ! -f "$ARIA2WebUIConfig" ]; then

		echo "ERROR - Aria 2 WEB Config file was not found"

		exit 1

	fi

	#Find pattern in Aria 2 config
	#.constant('$name', 'GAS home Aria2 WebUI. 12G free.')  // name used across the entire UI
	#12G is number 6 here - space as delimeter.
	ToFind=$(cat $ARIA2WebUIConfig | head -n 3 | tail -n 1 | awk -F' ' '{print $6}')

fi

if [ -d "$SAMBA" ]; then

	FREESPACE=$(df -hP $SAMBA | awk -F' ' '{print $4}' | tail -n 1)

	#Create a file with amount of free space in name "free_XXXGB_SALT.md"
	if [ "$FILE" = true ]; then

		TAIL=_.$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 )

		cd $SAMBA

		find $SAMBA/free_*$TAIL -exec rm {} \;

		touch free_$FREESPACE$TAIL

	fi

	#Adjust Aria2 WebUI
	if [ "$ARIA2" = true ]; then

		sed -i -e "s/$ToFind/$FREESPACE/g" $ARIA2WebUIConfig

	fi

	#Files Cleanup
	if [ "$CLEAN" = true ]; then

	#Check if config presented
	if [ ! -f "$ARIA2Config" ]; then

		echo "ERROR - Aria 2 Config file was not found"

		exit 1

	fi

		cd $SAMBA

		#Create TMP file
		if [ ! -f /tmp/df_for_samba.tmp ]; then

			touch /tmp/df_for_samba.tmp

		else

			rm /tmp/df_for_samba.tmp

			touch /tmp/df_for_samba.tmp

		fi

		#Create exception list
		grep .torrent $(grep save-session= /etc/aria2.conf | grep -v "#" | cut -c 14-) | rev | cut -c -48 | rev > /tmp/df_for_samba.tmp
		
		#Remove old torrent files except active downloads
		find *.torrent -mtime +$Older | fgrep -v -x -f /tmp/df_for_samba.tmp | xargs -d '\n' rm -f
		
		#Remove old aria2 files
		find *.aria2 -mtime +$Older -exec rm {} \;

		rm /tmp/df_for_samba.tmp

	fi

else
	echo "ERROR - Directory not found, or partition is not mounted"

	if [ "$ARIA2" = true ]; then

		sed -i -e "s/$ToFind/NOT_Mounted!/g" $ARIA2WebUIConfig

	fi

	exit 1
fi

exit 0

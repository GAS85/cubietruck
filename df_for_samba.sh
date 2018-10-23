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

	NameVariable=$(grep "\$name" $ARIA2WebUIConfig | cut -d "'" -f4 | cut -d "'" -f3)

	Check=$(echo $NameVariable | rev | cut -c -5 | rev)

	if [ "$Check" = "free." ]; then

		ToFind=$(echo $NameVariable | rev | awk -F' ' '{print $2}' | rev)

	fi

fi

if [ -d "$SAMBA" ]; then

	FREESPACE=$(df -hP $SAMBA | awk -F' ' '{print $4}' | tail -n 1)

	#Create a file with amount of free space in name "free_XXXGB_SALT.md"
	if [ "$FILE" = true ]; then

		TAIL=_.$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 )

		cd $SAMBA

		find $SAMBA/free_*$TAIL -exec rm {} \; 2> /dev/null

		touch free_$FREESPACE$TAIL

	fi

	#Adjust Aria2 WebUI
	if [ "$ARIA2" = true ]; then

		if [ "$Check" = "free." ]; then

			sed -i -e "s/$ToFind/$FREESPACE/g" $ARIA2WebUIConfig

		else

			sed -i -e "s/$NameVariable/$NameVariable. $FREESPACE free./g" $ARIA2WebUIConfig

		fi
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
		grep .torrent $(grep save-session= $ARIA2Config | grep -v "#" | cut -c 14-) | rev | cut -c -48 | rev > /tmp/df_for_samba.tmp
		
		#Remove old torrent files except active downloads
		find *.torrent -mtime +$Older | fgrep -v -x -f /tmp/df_for_samba.tmp | xargs -d '\n' rm -f
		
		#Remove old aria2 files
		find *.aria2 -mtime +$Older -exec rm {} \;  2> /dev/null

		rm /tmp/df_for_samba.tmp

	fi

else
	echo "ERROR - Directory not found, or partition is not mounted"

	if [ "$ARIA2" = true ]; then

		if [ "$Check" = "free." ]; then

			sed -i -e "s/$ToFind/$FREESPACE/g" $ARIA2WebUIConfig

		else

			sed -i -e "s/$NameVariable/$NameVariable. $FREESPACE free./g" $ARIA2WebUIConfig

		fi

	fi

	exit 1
fi

exit 0

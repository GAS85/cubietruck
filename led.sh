#!/bin/bash

# By Georgiy Sitnikov.
# AS-IS without any warranty

### Configuration start ###

#path to your LEDs
LEDs=/sys/class/leds/

#Brightness for "day". Maximum is 255 - not recomended.
BrightnessOn=50
#Brightness for "night"
BrightnessOff=0

#set trigger
#possible triggers: 
#none battery-charging-or-full battery-charging battery-full battery-charging-blink-full-solid ac-online usb-online mmc0 mmc1 timer disk-activity heartbeat backlight cpu0 cpu1 default-on rfkill0 rfkill1 rfkill2 rfkill4 
#Just delete the value of trigger and it will not be touched (e.g. as green)
	#for blue LED
	triggerB=disk-activity
	#for orange LED
	triggerO=cpu0
	#for white LED
	triggerW=cpu1
	#for green LED
	triggerG=mmc0

#Usually not need to be edited. Path to different LEDs.
blue=$LEDs/cubietruck:blue:usr
orange=$LEDs/cubietruck:orange:usr
white=$LEDs/cubietruck:white:usr
green=$LEDs/cubietruck:green:usr

### Configuration end ###

####################################
### DO NOT TOUCH AFTER THIS LINE ###
####################################

#Check if folder exist
if [[ ! -d "$LEDs" ]]; then

	echo "ERROR - LED Folder not found under $LEDs"

	exit 1

else
    
	if [[ ! -f "$blue/brightness" ]]; then

		echo "ERROR - LEDs not found under e.g. $blue"

		exit 1

	fi

fi

#set trigger
#possible triggers: 
#none rc-feedback rfkill-any rfkill-none kbd-scrolllock kbd-numlock kbd-capslock kbd-kanalock kbd-shiftlock kbd-altgrlock kbd-ctrllock kbd-altlock kbd-shiftllock kbd-shiftrlock kbd-ctrlllock kbd-ctrlrlock usbport disk-activity disk-read disk-write ide-disk mtd nand-disk heartbeat cpu cpu0 cpu1 [mmc0] default-on panic netdev mmc1 stmmac-0:00:link stmmac-0:00:1Gbps stmmac-0:00:100Mbps stmmac-0:00:10Mbps
#echo TRIGGER > $blue/trigger

if [[ $triggerB ]]; then

	echo $triggerB > $blau/trigger

fi

if [[ $triggerO ]]; then

	echo $triggerO > $orange/trigger

fi

if [[ $triggerW ]];  then

	echo $triggerW > $white/trigger

fi

if [[ $triggerG ]];  then

	echo $triggerG > $green/trigger

fi

#set brightness
##if Argument "off" to set low brightness, e.g. for night

if [[ $1 == "off" ]]; then

	if [[ $triggerB ]]; then

		echo $BrightnessOff > $blau/brightness

	fi

	if [[ $triggerO ]];  then

		echo $BrightnessOff > $orange/brightness

	fi

	if [[ $triggerW ]];  then

		echo $BrightnessOff > $white/brightness

	fi

	if [[ $triggerG ]];  then

		echo $BrightnessOff > $green/brightness

	fi

else

	if [[ $triggerB ]];  then

		echo $BrightnessOn > $blau/brightness

	fi

	if [[ $triggerO ]];  then

		echo $BrightnessOn > $orange/brightness

	fi

	if [[ $triggerW ]];  then

		echo $BrightnessOn > $white/brightness

	fi

	if [[ $triggerG ]]; then

		echo $BrightnessOn > $green/brightness

	fi

fi

exit 0

#!/bin/bash

# By Georgiy Sitnikov.
# AS-IS without any warranty

### Configuration start ###

#path to your LEDs
LEDs=/sys/class/leds/

#Brightness for "day"
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
	triggerG=

#Usually not need to be edited. Path to different LEDs.
blue=$LEDs/blue:ph21:led1
orange=$LEDs/orange:ph20:led2
white=$LEDs/white:ph11:led3
green=$LEDs/green:ph07:led4

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
#none battery-charging-or-full battery-charging battery-full battery-charging-blink-full-solid ac-online usb-online mmc0 mmc1 timer disk-activity heartbeat backlight cpu0 cpu1 default-on rfkill0 rfkill1 rfkill2 rfkill4 
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

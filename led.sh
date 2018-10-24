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
#Just delete value of trigger and it will not be touched (e.g. as green)
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
if [ -d "$SAMBA" ]; then

	echo "ERROR - LED Folder not found under $LEDs"

	exit 1

	if [ ! -f "$blue" ]; then

		echo "ERROR - LEDs not found under e.g. $blue"

		exit 1

	fi

fi

#set trigger
#possible triggers: 
#none battery-charging-or-full battery-charging battery-full battery-charging-blink-full-solid ac-online usb-online mmc0 mmc1 timer disk-activity heartbeat backlight cpu0 cpu1 default-on rfkill0 rfkill1 rfkill2 rfkill4 
#echo TRIGGER > $blue/trigger

echo $triggerB > $blau/trigger
echo $triggerO > $orange/trigger
echo $triggerW > $white/trigger
echo $triggerG > $green/trigger

#set brightness
##if Argument "off" to set low brightness, e.g. for night

if [[ $1 == "off" ]]
  then
	echo $BrightnessOff > $blau/brightness
	echo $BrightnessOff > $orange/brightness
	echo $BrightnessOff > $white/brightness
	echo $BrightnessOff > $green/brightness
  else
	echo $BrightnessOn > $blau/brightness
	echo $BrightnessOn > $orange/brightness
	echo $BrightnessOn > $white/brightness
	echo $BrightnessOn > $green/brightness
fi

exit 0

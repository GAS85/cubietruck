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
if [ -d "$LEDs" ]; then

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

if [ -z "$triggerB" ]; echo $triggerB > $blau/trigger
if [ -z "$triggerO" ]; echo $triggerO > $orange/trigger
if [ -z "$triggerW" ]; echo $triggerW > $white/trigger
if [ -z "$triggerG" ]; echo $triggerG > $green/trigger

#set brightness
##if Argument "off" to set low brightness, e.g. for night

if [[ $1 == "off" ]]

	then

		if [ -z "$triggerB" ]; echo $BrightnessOff > $blau/brightness
		if [ -z "$triggerO" ]; echo $BrightnessOff > $orange/brightness
		if [ -z "$triggerW" ]; echo $BrightnessOff > $white/brightness
		if [ -z "$triggerG" ]; echo $BrightnessOff > $green/brightness

	else

		if [ -z "$triggerB" ]; echo $BrightnessOn > $blau/brightness
		if [ -z "$triggerO" ]; echo $BrightnessOn > $orange/brightness
		if [ -z "$triggerW" ]; echo $BrightnessOn > $white/brightness
		if [ -z "$triggerG" ]; echo $BrightnessOn > $green/brightness

	fi

exit 0

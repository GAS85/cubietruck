#!/bin/bash

# By Georgiy Sitnikov.
# AS-IS without any warranty

### Configuration start ###

LEDs=/sys/class/leds/
blue=$LEDs/blue:ph21:led1
orange=$LEDs/orange:ph20:led2
white=$LEDs/white:ph11:led3
green=$LEDs/green:ph07:led4

#Brightness for "day"
BrightnessOn=50
#Brightness for "night"
BrightnessOff=0

### Configuration end ###

####################################
### DO NOT TOUCH AFTER THIS LINE ###
####################################

#set trigger
#possible triggers: 
#none battery-charging-or-full battery-charging battery-full battery-charging-blink-full-solid ac-online usb-online mmc0 mmc1 timer disk-activity heartbeat backlight cpu0 cpu1 default-on rfkill0 rfkill1 rfkill2 rfkill4 
#echo TRIGGER > $blue/trigger

echo disk-activity > $blau/trigger
echo cpu0 > $orange/trigger
echo cpu1 > $white/trigger
#echo mmc0 > $green/trigger

#set brightness
##if Argument "off" to set low brightness, e.g. for night

if [[ $1 == "off" ]]
  then
	echo BrightnessOn=50 > $blau/brightness
	echo BrightnessOn=50 > $orange/brightness
	echo BrightnessOn=50 > $white/brightness
#	echo BrightnessOn=50 > $green/brightness
  else
	echo $BrightnessOn > $blau/brightness
	echo $BrightnessOn > $orange/brightness
	echo $BrightnessOn > $white/brightness
#	echo $BrightnessOn > $green/brightness
fi

exit 0

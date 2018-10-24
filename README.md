# cubietruck
My Cubitruck Scripts

# battery_checker.sh

I create a script that will try to send Warning Email and and shutdown the system as soon as it goes below 10%.

I put it in cron hourly and script should automatically check and do loop if battery discharging and below e.g. 80%.

E-Mail is needed because last time I did not know that my power supply died and I did not know why sever stopped. This version is also producing logs that could be checked after cubietruck fails. That helps for trouble shooting, e.g. to find out that power supply could not produce enough current to charge battery.

Log output example:

    Tue Oct 16 10:01:03 CEST 2018 - Ok. Battery Full - 100% left. AC is online with current 0.222 A. Battery health is Good.

# df_for_samba.sh

Will put amount of free space in your ARIA2 WebUI header and also as file in share.
Delete old aria2 and inactive torrent files.

Example of Aria2 WebUI modification after this Script:
![image](https://user-images.githubusercontent.com/6813635/47412465-23b05a80-d76c-11e8-86c7-4da2987cb923.png)

# led.sh

Control your Cubietruck LEDs on Ubuntu 16.04 (Armbian). Has 2 parameters for "night" and "day". For Day just run it and for night modus run it with parameter "off"

    led.sh off

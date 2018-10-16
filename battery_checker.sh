#!/bin/bash
# You can edit this
recipients="email1@xxxx.com,email2@yyyy.com"
subject="Power supply problems"
from="noreplay@YOUR_DOMAIN"
# Set battery critical level to shudown the server
critical_level=10
# Set battery warning level
warning_level=80
# Set log file path
LOGFILE=/var/log/battery_checker.log

# Please DO NOT TOUCH under this line

LOCKFILE=/tmp/battery_checker

# Check if Log file exist
[ -e $LOGFILE ] || { echo >&2 "Log File ($LOGFILE) does't exist."; exit 1; }
# Check if Log file is writtable by Process
[ -w $LOGFILE ] || { echo >&2 "Log File ($LOGFILE) is not writable by process."; exit 1; }
# Check if you are root user, otherwise shutdown will not work
[ $(id -u) -eq 0 ] || { echo >&2 "Must be root to run script"; exit 1; }
# Check if sendmail exist
[ -e /usr/sbin/sendmail ] || echo >&2 "Sendmail does't installed, will not be able to send E-Mails."

batt_capacity="$(cat /sys/class/power_supply/battery/capacity)"
batt_p="$(cat /sys/class/power_supply/battery/present)"
ac_p="$(cat /sys/class/power_supply/ac/online)"
ac_cur="$(printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)")" #Current in A

#echo "$(date) - Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left." >> $LOGFILE

# check if Battery presented otherwise it is useless:)
[ "$batt_p" == "0" ] && echo "$(date) - Abort. Battery not presented." >> $LOGFILE && exit 0
# check if AC is online
[ "$ac_p" == "1" ] && echo "$(date) - Ok. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. AC is online with current $ac_cur A. Battery health is $(cat /sys/class/power_supply/battery/health)." >> $LOGFILE && exit 0 ##Commented exit 0 because if AC faulty - it will not charge, but scipt exiting
# check if Battery dischared to 80%
[ "$batt_capacity" -ge "$warning_level" ] && echo "$(date) - Warning. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. AC is $([ "$ac_p" == "1" ] && echo "online" || echo "offline") with current $ac_cur A. Battery health is $(cat /sys/class/power_supply/battery/health)." >> $LOGFILE && exit 0

# Check lock file
#[ -f "$LOCKFILE" ] && exit
if [ -f "$LOCKFILE" ]; then
        # Remove lock file if script fails last time and did not run more then 2 days due to lock file.
        #find "$LOCKFILE" -mtime +2 -type f -delete && echo "$(date) - Error. Lock file older than 2 days was deleted." >> $LOGFILE && exit 1
        find "$LOCKFILE" -mtime +2 -type f -delete && { echo >&2 "$(date) - Error. Lock file presented. Other instance?" >> $LOGFILE; exit 1; }
        exit 0
fi

touch $LOCKFILE

echo "$(date) - Warning. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. AC is offline. Battery health is $(cat /sys/class/power_supply/battery/health). Start watching." >> $LOGFILE

# Here we could send warning message
echo "To: $recipients" > $LOCKFILE
echo "FROM: $from" >> $LOCKFILE
echo "Subject: $subject" >> $LOCKFILE
echo "MIME-Version: 1.0" >> $LOCKFILE
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"' >> $LOCKFILE
echo >> $LOCKFILE
echo '---q1w2e3r4t5' >> $LOCKFILE
echo "Content-Type: text/html" >> $LOCKFILE
echo "Content-Disposition: inline" >> $LOCKFILE
echo "" >> $LOCKFILE
echo "Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left.<br>Battery health is $(cat /sys/class/power_supply/battery/health).<br>Will shutdown at $critical_level%.<br>$(date)<br>Internal IP: $(ip route get 8.8.8.8 | awk '{print $NF; exit}')<br>Hostname: $(hostname)<br><br>" >> $LOCKFILE
cat /sys/class/power_supply/ac/uevent >> $LOCKFILE
echo "<br>" >> $LOCKFILE
cat /sys/class/power_supply/battery/uevent >> $LOCKFILE

echo "$(date) - Send warning E-Mail" >> $LOGFIL
cat $LOCKFILE | /usr/sbin/sendmail $recipients

#echo Starting periodical check
for (( ; ; ))
do
	batt_capacity="$(cat /sys/class/power_supply/battery/capacity)"
	ac_p="$(cat /sys/class/power_supply/ac/online)"

	#if battery charged again - exit
	if [ $batt_capacity -gt $warning_level ]; then
	    	if [ "$ac_p" == "1" ]; then
        		echo "$(date) - Ok. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left.  AC is $([ "$ac_p" == "1" ] && echo "online" || echo "offline") with current $ac_cur A. Battery health is $(cat /sys/class/power_supply/battery/health). Exiting." >> $LOGFIL
			#echo "$(date) - Ok. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. Exiting." >> $LOGFILE
			rm $LOCKFILE
			exit 0
		fi
		echo "$(date) - Warning. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. AC is $([ "$ac_p" == "1" ] && echo "online" || echo "offline") with current $ac_cur A. Battery health is $(cat /sys/class/power_supply/battery/health) Watching." >> $LOGFIL
	fi

	#if battery critical discharded - turn server Off
	if [ $batt_capacity -le $critical_level ]; then break
	fi

	#pause pefore next periodical check
	sleep 2m

done

#echo Here we could send warning message
#Email Header
echo "To: $recipients" > $LOCKFILE
echo "FROM: $from" >> $LOCKFILE
echo "Subject: $subject. Shutdown now." >> $LOCKFILE
echo "MIME-Version: 1.0" >> $LOCKFILE
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"' >> $LOCKFILE
echo >> $LOCKFILE
echo '---q1w2e3r4t5' >> $LOCKFILE
echo "Content-Type: text/html" >> $LOCKFILE
echo "Content-Disposition: inline" >> $LOCKFILE
echo "" >> $LOCKFILE
echo "Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left.<br>Critical level ($critical_level%) reached - shutdown now.<br>Battery health is $(cat /sys/class/power_supply/battery/health).<br>$(date)<br>Internal IP: $(ip route get 8.8.8.8 | awk '{print $NF; exit}')<br>Hostname: $(hostname)<br><br>" >> $LOCKFILE
cat /sys/class/power_supply/ac/uevent >> $LOCKFILE
echo "<br>" >> $LOCKFILE
cat /sys/class/power_supply/battery/uevent >> $LOCKFILE

# Write to log
echo "$(date) - Warning. Battery $(cat /sys/class/power_supply/battery/status) - $batt_capacity% left. Critical level ($critical_level%) reached - shutdown now.  AC is $([ "$ac_p" == "1" ] && echo "online" || echo "offline") with current $ac_cur A. Battery health is $(cat /sys/class/power_supply/battery/health)." >> $LOGFILE

# Send Email
cat $LOCKFILE | /usr/sbin/sendmail $recipients

#remove temporary files
rm $LOCKFILE

##sleeping before shutdown
sleep 5s

shutdown -P now

exit 0

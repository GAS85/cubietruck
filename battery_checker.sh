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

# Check if you are root user, otherwise shutdown will not work
[ $(id -u) -eq 0 ] || { echo >&2 "Must be root to run this script."; exit 1; }
# # Check if Log file exist
[ -e $LOGFILE ] || { echo >&2 "Log File ($LOGFILE) does't exist."; exit 1; }
# Check if Log file is writtable by Process
[ -w $LOGFILE ] || { echo >&2 "Log File ($LOGFILE) is not writable by process."; exit 1; }
# Check if sendmail exist
[ -e /usr/sbin/sendmail ] || echo >&2 "Sendmail does't installed, will not be able to send E-Mails."

batt_capacity="/sys/class/power_supply/battery/capacity"
batt_p="/sys/class/power_supply/battery/present"
batt_status="/sys/class/power_supply/battery/status"
batt_health="/sys/class/power_supply/battery/health"
ac_p="/sys/class/power_supply/ac/online"
ac_cur="$(printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)")" #Current in A

# check if Battery presented otherwise it is useless:)
[ "$(cat $batt_p)" == "0" ] && echo "$(date) - Abort. Battery not presented." >> $LOGFILE && exit 0

# Check lock file
if [ -f "$LOCKFILE" ]; then
        # Remove lock file if script fails last time and did not run more then 2 days due to lock file.
        find "$LOCKFILE" -mtime +2 -type f -delete && { echo >&2 "$(date) - Error. Lock file presented. Other instance?" >> $LOGFILE; exit 1; }
        exit 0
fi

touch $LOCKFILE

# check if Battery dischared to 80%
if [ "$(cat $batt_capacity)" -gt "$warning_level" ]; then
	if [ "$(cat $ac_p)" == "1" ]; then
		echo "$(date) - Ok. Battery $(cat $batt_status) - $(cat $batt_capacity)% left.  AC is $([ "$(cat $ac_p)" == "1" ] && echo "online" || echo "offline") with current $$ac_cur A. Battery health is $(cat $batt_health)." >> $LOGFILE
		rm $LOCKFILE
		exit 0
	fi
	echo "$(date) - Warning. Battery $(cat $batt_status) - $(cat $batt_capacity)% left. AC is $([ "$(cat $ac_p)" == "1" ] && echo "online" || echo "offline") with current $$ac_cur A. Battery health is $(cat $batt_health) Start watching." >> $LOGFILE
fi

# Here we could send warning message
echo 'To: '$recipients'
FROM: '$from'
Subject: '$subject'. Start watching.
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"

---q1w2e3r4t5
Content-Type: text/html
Content-Disposition: inline

Battery '$(cat $batt_status)' - '$(cat $batt_capacity)'% left, health is '$(cat $batt_health)'.<br>
Will shutdown at '$critical_level'%.<br><br>
'$(date)'<br><br>
Internal IP: '$(ip route get 8.8.8.8 | awk '{print $NF; exit}')'<br>
Hostname: '$(hostname)'<br><br>
'$(cat /sys/class/power_supply/ac/uevent)'<br><br>
'$(cat /sys/class/power_supply/battery/uevent)'' > $LOCKFILE

echo "$(date) - Send warning E-Mail" >> $LOGFILE

cat $LOCKFILE | /usr/sbin/sendmail $recipients

#echo Starting periodical check
for (( ; ; ))
do
	#if battery charged again - exit
	if [ "$(cat $batt_capacity)" -gt "$warning_level" ]; then
		if [ "$(cat $ac_p)" == "1" ]; then
			echo "$(date) - Ok. Battery $(cat $batt_status) - $(cat $batt_capacity)% left.  AC is $([ "$(cat $ac_p)" == "1" ] && echo "online" || echo "offline") with current $(printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)") A. Battery health is $(cat $batt_health). Exiting." >> $LOGFILE
			rm $LOCKFILE
			exit 0
		fi
		echo "$(date) - Warning. Battery $(cat $batt_status) - $(cat $batt_capacity)% left. AC is $([ "$(cat $ac_p)" == "1" ] && echo "online" || echo "offline") with current $(printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)") A. Battery health is $(cat $batt_health) Watching." >> $LOGFIL
	fi

	#if battery critical discharded - turn server Off
	if [ "$(cat $batt_capacity)" -le "$critical_level" ]; then break
	fi

	#pause pefore next periodical check
	sleep 2m

done

#echo Here we could send warning message
#Email Header
echo 'To: '$recipients'
FROM: '$from'
Subject: '$subject'. Shutdown now.
MIME-Version: 1.0"
Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"

---q1w2e3r4t5
Content-Type: text/html
Content-Disposition: inline

Battery '$(cat $batt_status)' - '$(cat $batt_capacity)'% left.<br>
Critical level ('$critical_level'%) reached - shutdown now.<br>
Battery health is '$(cat $batt_health)'.<br><br>
'$(date)'<br><br>
Internal IP: '$(ip route get 8.8.8.8 | awk '{print $NF; exit}')'<br>
Hostname: '$(hostname)'<br><br>
'$(cat /sys/class/power_supply/ac/uevent)'<br><br>
'$(cat /sys/class/power_supply/battery/uevent)'' > $LOCKFILE

# Write to log
echo "$(date) - Warning. Battery $(cat $batt_status) - $(cat $batt_capacity)% left. Critical level ($critical_level%) reached - shutdown now.  AC is $([ "$(cat $ac_p)" == "1" ] && echo "online" || echo "offline") with current $(printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)") A. Battery health is $(cat $batt_health)." >> $LOGFILE

# Send Email
cat $LOCKFILE | /usr/sbin/sendmail $recipients

#remove temporary files
rm $LOCKFILE

##sleeping before shutdown
sleep 5s

shutdown -P now

exit 0

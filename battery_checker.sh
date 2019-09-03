#!/bin/bash

# You can edit this
Send_warning_email=true
RECIPIENTS="email1@xxxx.com,email2@yyyy.com"
SUBJECT="Power supply problems"
FROM="noreplay@YOUR_DOMAIN"

# Set battery critical level to shudown the server
CRITICAL_LVL=12

# Set battery warning level
WARNING_LVL=80

# Set log file path
LOG_FILE=/var/log/battery_checker.log

###
### Please DO NOT TOUCH under this line ###

BATTERY=/sys/power/axp_pmu/battery
AC=/sys/power/axp_pmu/ac
LOCK_FILE=/tmp/battery_checker

will_shut_down=0

# Check if you are root user, otherwise shutdown will not work
[[ $(id -u) -eq 0 ]] || { echo >&2 "Must be root to run this script."; exit 1; }

# Check if Log file exist
[[ -e $LOG_FILE ]] || { echo >&2 "Log File ($LOG_FILE) does't exist. Creating one."; touch $LOG_FILE; }

# Check if Log file is writtable by Process
[[ -w $LOG_FILE ]] || { echo >&2 "Log File ($LOG_FILE) is not writable by process."; exit 1; }

# Check if sendmail exist
[[ -e /usr/sbin/sendmail ]] || { echo >&2 "Sendmail not installed, will not be able to send Send_EMails."; Send_warning_email=false; }

batt_capacity () {
	cat $BATTERY/capacity
}

batt_status () {
	[[ "$(cat $BATTERY/charging)" == 1 ]] && echo "charging" || echo "not charging"
}

batt_present () {
	[[ "$(cat $BATTERY/connected)" == 1 ]] && echo "connected" || echo "diconnected"
}

#batt_health () {
#	cat $BATTERY/health
#}

ac_present () {
	[[ "$(cat $AC/connected)" = "1" ]] && echo "online" || echo "offline"
}

ac_current () {
	printf "%0.3f\n" "$(echo "$(cat $AC/amperage)" / 1000000 | bc -l)"
}

write_log () {
	echo "$(date) - $STATUS. Battery $(batt_status) - $(batt_capacity)% left. AC is $(ac_present) with current $(ac_current) A. $MESSAGE" >> $LOG_FILE
	STATUS=""
	MESSAGE=""
}

Send_EMail () {
	if [ "$Send_warning_email" == true ]; then

		#STATUS="Warning"
		#MESSAGE="Send warning E-Mail"
		#write_log

		echo 'To: '$RECIPIENTS'
FROM: '$FROM'
SUBJECT: '$SUBJECT'. '$([[ "$will_shut_down" = "1" ]] && echo 'Shutdown now.' || echo 'Start watching.')'
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"

---q1w2e3r4t5
Content-Type: text/html
Content-Disposition: inline

Battery '$(batt_status)' - '$(batt_capacity)'% left.<br>
'$([[ "$will_shut_down" = "1" ]] && echo "Critical level ($CRITICAL_LVL%) reached - shutdown now.<br><br>" || echo "Will shutdown at $CRITICAL_LVL%.<br><br>")'
'$(date)'<br><br>
Internal IP: '$(ip route get 8.8.8.8 | awk '{print $7; exit}')'<br>
Hostname: '$(hostname)'<br><br>' > $LOCK_FILE

		echo "$(date) - Send warning E-Mail." >> $LOG_FILE

		cat $LOCK_FILE | /usr/sbin/sendmail $RECIPIENTS

		will_shut_down=0
	fi	
}

# check if Battery presented otherwise it is useless:)
if [ "$(batt_present)" == "disconnected" ]; then

	echo "$(date) - Abort. Battery not presented." >> $LOG_FILE
	exit 0

fi

# Check lock file
[[ -e $LOCK_FILE ]] || touch $LOCK_FILE #&& echo > $LOCK_FILE

#if battery critical discharded - turn server Off
if [ "$(batt_capacity)" -le $CRITICAL_LVL ]; then


	# Write to log
	STATUS="Warning"
	MESSAGE="Shutdown now."
	write_log

	#echo Here we could send warning message
	will_shut_down=1
	Send_EMail

	#remove temporary files
	rm $LOCK_FILE

	#sleeping before shutdown
	sleep 5s
	shutdown -P now
	exit 0
fi

# check if Battery dischared to WARNING_LVL, e.g. 80%
if [ "$(batt_capacity)" -le $WARNING_LVL ]; then

	if [ "$(ac_present)" == "online" ]; then

		STATUS="Ok"
		write_log
		rm $LOCK_FILE

		[[ -e $LOCK_FILE.WarningMailWasSend ]] || { touch $LOCK_FILE.WarningMailWasSend; Send_EMail; }

		exit 0

	fi

	STATUS="Warning"
	write_log

	[[ -e $LOCK_FILE.WarningMailWasSend ]] || { touch $LOCK_FILE.WarningMailWasSend; Send_EMail; }

	rm $LOCK_FILE
	exit 0
fi

# Here we could send warning message

rm $LOCK_FILE
rm $LOCK_FILE.WarningMailWasSend

exit 0

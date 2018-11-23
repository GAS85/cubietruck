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

LOCK_FILE=/tmp/battery_checker

will_shut_down=0

# Check if you are root user, otherwise shutdown will not work
[[ $(id -u) -eq 0 ]] || { echo >&2 "Must be root to run this script."; exit 1; }

# Check if Log file exist
[[ -e $LOG_FILE ]] || { echo >&2 "Log File ($LOG_FILE) does't exist."; exit 1; }

# Check if Log file is writtable by Process
[[ -w $LOG_FILE ]] || { echo >&2 "Log File ($LOG_FILE) is not writable by process."; exit 1; }

# Check if sendmail exist
[[ -e /usr/sbin/sendmail ]] || { echo >&2 "Sendmail not installed, will not be able to send Send_EMails."; Send_warning_email=false; }

batt_capacity () {
	cat /sys/class/power_supply/battery/capacity
}

batt_status () {
	cat /sys/class/power_supply/battery/status
}

batt_present () {
	cat /sys/class/power_supply/battery/present
}

batt_health () {
	cat /sys/class/power_supply/battery/health
}

ac_present () {
	cat /sys/class/power_supply/ac/online
}

ac_current () {
	printf "%0.3f\n" "$(echo "$(cat /sys/class/power_supply/ac/current_now)" / 1000000 | bc -l)"
}

write_log () {
	echo "$(date) - $STATUS. Battery $(batt_status) - $(batt_capacity)% left. AC is $([[ "$(ac_present)" = "1" ]] && echo "online" || echo "offline") with current $(ac_current) A. Battery health is $(batt_health). $MESSAGE" >> $LOG_FILE
	STATUS=""
	MESSAGE=""
}

Send_EMail () {
	if [[ "$Send_warning_email" == true ]]; then

		echo 'To: '$RECIPIENTS'
FROM: '$FROM'
SUBJECT: '$SUBJECT'. '$([[ "$will_shut_down" = "1" ]] && echo 'Shutdown now.' || echo 'Start watching.')'
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"

---q1w2e3r4t5
Content-Type: text/html
Content-Disposition: inline

Battery '$(batt_status)' - '$(batt_capacity)'% left, health is '$(batt_health)'.<br>
'$([[ "$will_shut_down" = "1" ]] && echo "Critical level ($CRITICAL_LVL%) reached - shutdown now.<br><br>" || echo "Will shutdown at $CRITICAL_LVL%.<br><br>")'
'$(date)'<br><br>
Internal IP: '$(ip route get 8.8.8.8 | awk '{print $NF; exit}')'<br>
Hostname: '$(hostname)'<br><br>
'$(cat /sys/class/power_supply/ac/uevent)'<br><br>
'$(cat /sys/class/power_supply/battery/uevent)'' > $LOCK_FILE

		echo "$(date) - Send warning E-Mail." >> $LOG_FILE

		cat $LOCK_FILE | /usr/sbin/sendmail $RECIPIENTS

		will_shut_down=0
	fi	
}

# check if Battery presented otherwise it is useless:)
if [[ "$(batt_present)" == 0 ]]; then

	echo "$(date) - Abort. Battery not presented." >> $LOG_FILE
	exit 0

fi

# Check lock file
if [[ -f $LOCK_FILE ]]; then

        # Remove lock file if script fails last time and did not run more then 2 days due to lock file.
        find "$LOCK_FILE" -mtime +2 -type f -delete && { echo >&2 "$(date) - Error. Lock file presented. Other instance?" >> $LOG_FILE; exit 1; }
        exit 0

fi

touch $LOCK_FILE

# check if Battery dischared to WARNING_LVL, e.g. 80%
if [[ "$(batt_capacity)" -gt $WARNING_LVL ]]; then

	if [[ "$(ac_present)" == "1" ]]; then

		STATUS="Ok"
		write_log
		rm $LOCK_FILE
		exit 0

	fi

	STATUS="Warning"
	write_log

fi

# Here we could send warning message
Send_EMail

#echo Starting periodical check
for (( ; ; ))
do
	#if battery charged again - exit
	if [[ "$(batt_capacity)" -gt $WARNING_LVL ]]; then

		if [[ "$(ac_present)" == "1" ]]; then

			STATUS="Ok"
			MESSAGE="Exiting."
			write_log
			rm $LOCK_FILE
			exit 0

		fi

		STATUS="Warning"
		MESSAGE="Watching."
		write_log

	fi

	#if battery critical discharded - turn server Off
	if [[ "$(batt_capacity)" -le $CRITICAL_LVL ]]; then break
	fi

	#pause pefore next periodical check
	sleep 2m

done

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


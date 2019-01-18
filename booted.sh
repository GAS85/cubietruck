#!/bin/bash

# By Georgiy Sitnikov.
# Simple script to send information E-Mail when booted
# Please added to cron as
#
# @reboot /PATH/booted.sh
#
# AS-IS without any warranty

# You can edit this

RECIPIENTS="recipient@mailserver.com"
SUBJECT="I'm UP"
FROM="noreplay@YOUR_DOMAIN"

LOCK_FILE=/tmp/booted_mail.tmp

touch $LOCK_FILE

# Added pause to whait for all systems up
sleep 60

echo 'To: '$RECIPIENTS'
FROM: '$FROM'
SUBJECT: '$SUBJECT'. '$(hostname)'
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"

---q1w2e3r4t5
Content-Type: text/html
Content-Disposition: inline

Hostname: '$(hostname)'<br>
Internal IP: '$(ip route get 8.8.8.8 | awk '{print $NF; exit}')'<br>
External IP: '$(curl -s ipinfo.io/ip)'<br><br>
Disk information: '$(df -h)'<br><br>
'$(cat /sys/class/power_supply/ac/uevent)'<br><br>
'$(cat /sys/class/power_supply/battery/uevent)'' > $LOCK_FILE

cat $LOCK_FILE | /usr/sbin/sendmail $RECIPIENTS


rm $LOCK_FILE

exit 0

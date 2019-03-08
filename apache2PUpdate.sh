#!/bin/bash

apache2Conf="/etc/apache2/sites-enabled/900-restrictDirectIP.conf"

# Functions

# IP Validator
# http://www.linuxjournal.com/content/validating-ip-address-bash-script
function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Program

GET_IP_URLS[0]="https://api.ipify.org"
GET_IP_URLS[1]="http://icanhazip.com"
GET_IP_URLS[2]="http://wtfismyip.com/text"
GET_IP_URLS[3]="http://nst.sourceforge.net/nst/tools/ip.php"

GIP_INDEX=0

while [ -n "${GET_IP_URLS[$GIP_INDEX]}" ] && ! valid_ip $NEWIP; do
    NEWIP=$(curl -s ${GET_IP_URLS[$GIP_INDEX]} | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    let GIP_INDEX++
done

if ! valid_ip $NEWIP; then
    echo Could not find current IP
    exit 1
fi

echo "IP: $NEWIP"

#Update Apache2 Config
original=$(grep ServerName $apache2Conf | awk '{print $2}' | head -n 1)

if [ "$original" == "$NEIP" ]; then
        exit 0
else
        sed -i "s/$original/$NEWIP/g" $apache2Conf
        service apache2 reload
fi

exit 0

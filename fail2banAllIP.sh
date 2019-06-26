#!/bin/bash

# By Georgiy Sitnikov.
# AS-IS without any warranty

fail2banLogFile=/var/log/fail2ban.log
Apache2Log=/var/log/apache2

resultsFile_day=/tmp/fail2ban_all_IP_day.log
resultsFile_all=/var/log/fail2ban_all_IP_all.log

dokuWikiBin=/var/www/dokuwiki/bin
dokuWikiData=$dokuWikiBin/../data

dokuWikiNamespace="gas:fail2ban"
dokuWikiUser=gas

geoApiKey=fsdsdfsdfsdfsdf
abuseIpDbApiKey=sdsdffsdsdfsdfsdfsdf2
abuseCategories="14,15"

tmp=/tmp/fail2ban_dokuwikiIPs.tmp

tillTime="$(date +"%H")"
if [ "$tillTime" == "00" ]; then

	fromTime=21
	tillTime=23

else

	fromTime="$(echo $tillTime - 3 | bc -l)"

fi

#Break on any error, also API Call error like 4xx
#set -e

# Check if you are root user
[[ $(id -u) -eq 0 ]] || { echo >&2 "Must be root to run this script."; exit 1; }

# Check if Log file exist
[[ -e $fail2banLogFile ]] || { echo >&2 "Log File ($fail2banLogFile) does't exist."; exit 1; }

# Check if Log file exist
[[ -e $Apache2Log ]] || { echo >&2 "Log File ($Apache2Log) does't exist."; exit 1; }

dokuWikiChown=$dokuWikiData
dokuWikiData=$dokuWikiData/pages/${dokuWikiNamespace//:/\/}
dokuWikiReport=$dokuWikiNamespace":BlockedIPs"

webServerUser=$(stat -c '%U' $dokuWikiData)
webServerGroup=$(stat -c '%G' $dokuWikiData)

searchInLogFail2Ban () {
	awk -F'[: ]' '$2 >= '$fromTime' && $2 <= '$tillTime' { print }' $1
}

searchInLogApache () {
	awk -F'[:]' '$2 >= '$fromTime' && $2 <= '$tillTime' { print }'
}

commitComment=Update

dokuWikiCommit () {
	php $dokuWikiBin/dwpage.php -u $dokuWikiUser commit -m $1 $2 $3 >> /dev/null
}

reportIPs () {
# Report only uniq
uniq $tmp > $tmp.report

	while read in; do

		if [ -f "$dokuWikiData/$in.txt" ]; then

			abuseComment=$(tail -n 1 $dokuWikiData/$in.txt | awk -F'["]' '{print $2}')

			if [ "$abuseComment" == "GET / HTTP/1.1" -o "$abuseComment" == "GET / HTTP/1.0" -o "$abuseComment" == "GET / HTTP/2.0" ]; then

				abuseComment="Port scan and direct access per IP instead of hostname"

			fi

		else

			# abuseComment=""
			abuseComment=$(grep "$in - - " $Apache2Log/*.log $Apache2Log/*.log.1 | searchInLogApache | awk -F'["]' '{print $2}' | tail -n 1)

		fi

		reportIPApi="$(curl -s https://api.abuseipdb.com/api/v2/report \
		-H "Accept: application/json" \
		-H "Key: $abuseIpDbApiKey" \
		--data-urlencode "ip=$in" \
		--data-urlencode "comment=$abuseComment" \
		--data "categories=$abuseCategories")"

		checkApiOnErrorVar=$reportIPApi
		checkApiOnError

	done < $tmp.report
}

addedToDokuwiki () {
	while read in; do

		commitComment=New

		if [ -f "$dokuWikiData/$in.txt" ]; then

			uniq $dokuWikiData/$in.txt > $tmp$in
			commitComment=Update

		fi

		grep "$in - - " $Apache2Log/*.log | searchInLogApache | uniq | awk -F'[:]' '{ $1 = ""; print "    " $0 }' >> $tmp$in

		if [ $(wc -c <"$tmp$in") -ge 2 ]; then

			dokuWikiCommit $commitComment $tmp$in $dokuWikiNamespace:$in >> /dev/null

		fi

	done < $tmp
}

geolocation () {
	geolocationApi="$(curl -s 'https://api.ipgeolocation.io/ipgeo?apiKey='$geoApiKey'&ip='"$(echo $in | awk '{print $2}')"'&fields=country_flag,country_name,city,isp')"

	checkApiOnErrorVar=$geolocationApi
	checkApiOnError

	echo $geolocationApi
}

checkApiOnError () {
	# Check if Abuse API call error
	if [ "$(echo $checkApiOnErrorVar | awk -F'["]' '{print $2}')" == "errors" ]; then

		echo >&2 "API Call error. $(echo $checkApiOnErrorVar | awk -F'["]' '{print $6}')"
		# exit 1

	fi
	# Check if Geolocation call error
	if [ "$(echo $checkApiOnErrorVar | awk -F'["]' '{print $2}')" == "message" ]; then

		echo >&2 "API Call error. $(echo $checkApiOnErrorVar | awk -F'["]' '{print $4}')"
		# exit 1

	fi
}

abusecheck () {
	abusestatusCheckApi="$(curl -s -G https://api.abuseipdb.com/api/v2/check \
	--data-urlencode "ipAddress=$(echo $in | awk '{print $2}')" \
	-H "Key: $abuseIpDbApiKey" \
	-H "Accept: application/json")"

	checkApiOnErrorVar=$abusestatusCheckApi
	checkApiOnError

	abusestatusValue="$(echo $abusestatusCheckApi | awk -F'["]' '{print $15}' | cut -c 2- | rev | cut -c 2- | rev)"
	abusestatus="|<progrecss $abusestatusValue% />"
}

createDokuWikiReport () {
	SECONDS=0
#	start=`date +%s`

	cat $resultsFile_all | uniq -c | sort -g -r > $tmp

	echo "====== Fail2Ban List of blocked IP addresses ======" > $tmp.2
	echo "Total unique IPs: $(wc -l $tmp | awk '{print $1}')" >> $tmp.2
	echo "" >> $tmp.2
	# Enable Sortable Plugin https://www.dokuwiki.org/plugin:sortablejs
	echo "<sortable>" >> $tmp.2
	# Header
	echo "^Hits^Who-is, Abuse^IP^Confidence of Abuse^Flag^Country^City^ISProvider^" >> $tmp.2

	# Retrive IP Info
	while read in; do abusecheck; echo $in | awk '{print $1}' | geolocation | awk -v var="$abusestatus" -F'["]' '{ print "|" $4 var "|{{" $8 "?32x32&cache}}|" $12 "|" $16 "|" $20 "|"}' >> $tmp.2; done < $tmp

	# Close TAG for Sortable Plugin
	echo "</sortable>" >> $tmp.2

	# Added Hits Number
	while read in; do sed -i -e 's/|'"$(echo $in  | awk '{print $2}')"'/'"$(echo $in  | awk '{print "|" $1 "|[[https:\/\/whois.domaintools.com\/" $2 "|W]] [[https:\/\/www.abuseipdb.com\/check\/" $2 "|A]]|[[gas:fail2ban:" $2 "|" $2 "]]"}')"'/g' $tmp.2; done < $tmp

	duration=$SECONDS
#	end=`date +%s`

	echo "//It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to generate this list. Last update on $(date +"%Y-%m-%d")//" >> $tmp.2

	# Applay wiki Changes
	#commitComment=Update
	dokuWikiCommit Update $tmp.2 $dokuWikiReport >> /dev/null

	rm $tmp.2
}

# Search in fail2Ban for banned IPs
searchInLogFail2Ban $fail2banLogFile | grep Ban | grep -v 'ERROR\|Unban' | awk 'NF>1{print $NF}' | sort > $tmp

cat $tmp >> $resultsFile_day

addedToDokuwiki

reportIPs

if [ "$tillTime" == "23" ]; then

	cat $resultsFile_all >> $resultsFile_day
	cat $resultsFile_day | sort > $resultsFile_all
	rm $resultsFile_day

	createDokuWikiReport

fi

#Find and chown all files NOT from this user
cd $dokuWikiChown
find . ! -user $webServerUser -exec chown $webServerUser:$webServerGroup {} \;
rm $tmp*

exit 0

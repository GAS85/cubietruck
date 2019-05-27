#!/bin/bash

# By Georgiy Sitnikov.
# Will create DokuWiki page with all blocked IPs with check against
# ipgeolocation and abuseipdb
# AS-IS without any warranty

fail2banLogFile=/var/log/fail2ban.log
Apache2Log=/var/log/apache2

statisticFile=/tmp/fail2ban_all_IP_top.log
resultsFile_day=/tmp/fail2ban_all_IP_day.log
resultsFile_all=/var/log/fail2ban_all_IP_all.log

dokuwiki=/var/www/dokuwiki/data/pages/gas/fail2ban
dokuwikiReportFile=/var/www/dokuwiki/data/pages/gas/fail2ban/blockedips.txt

geoApiKey=sfsfdsfdsdf
abuseIpDbApiKey=sdsfsf3332dsdfsdf
abuseCategories="14,15"

tmp=/tmp/fail2ban_dokuwikiIPs.tmp

topAmount=20

tillTime="$(date +"%H")"
if [ "$tillTime" == "00" ]; then

	fromTime=21
	tillTime=23

else

	fromTime="$(echo $tillTime - 3 | bc -l)"

fi

reportIPs () {
	while read in; do

		if [ -f "$dokuwiki/$in.txt" ]; then

			abuseComment=$(tail -n 1 $dokuwiki/$in.txt | awk -F'["]' '{print $2}')

			if [ "$abuseComment" == "GET / HTTP/1.1" ]; then

				abuseComment=""

			fi

		else

			abuseComment=""

		fi

		curl -s --tlsv1.0 --fail 'https://api.abuseipdb.com/api/v2/report' \
		-H 'Accept: application/json' \
		-H 'Key: '$abuseIpDbApiKey'' \
		--data-urlencode 'ip='"$(echo $in | awk '{print $2}')"'' \
		--data-urlencode 'comment='"$abuseComment"'' \
		--data 'categories='"$abuseCategories"'' > /dev/null

	done < $tmp
}

addedToDokuwiki () {
	while read in; do

		grep "$(echo $in) - - " $Apache2Log/*.log | awk -F'[:]' '{ $1 = ""; print "    " $0 }' >> $dokuwiki/$in.txt

	done < $tmp

	# Set corrct access rules and delete empty pages
	find $dokuwiki/*.txt -empty -type f -delete
	chown www-data:www-data $dokuwiki/*.txt
}

geolocation () {
	curl -s --fail 'https://api.ipgeolocation.io/ipgeo?apiKey='$geoApiKey'&ip='"$(echo $in | awk '{print $2}')"'&fields=country_flag,country_name,city,isp'
}

abusecheck () {
	abusestatus_value="$(curl -s -G --fail https://api.abuseipdb.com/api/v2/check --data-urlencode "ipAddress=$(echo $in | awk '{print $2}')" -H "Key: $abuseIpDbApiKey" -H "Accept: application/json" | awk -F'["]' '{print $15}' | cut -c 2- | rev | cut -c 2- | rev)"
	abusestatus="|<progrecss $abusestatus_value% />"
}

createDokuWikiReport () {
	start=`date +%s`

	cat $resultsFile_all | uniq -c | sort -g -r > $tmp

	echo "====== Fail2Ban List of blocked IP addresses ======" > $tmp.2
	echo "Total unique IPs: $(wc -l $tmp | awk '{print $1}')" >> $tmp.2
	echo "" >> $tmp.2
	# Enable Sortable Plugin https://www.dokuwiki.org/plugin:sortablejs
	echo "<sortable>" >> $tmp.2
	# Header
	echo "^Hits^Who-is, Abuse^IP^Confidence of Abuse^Flag^Country^City^ISProvider^" >> $tmp.2

	# Pattern
	# curl -s 'https://api.ipgeolocation.io/ipgeo?apiKey=53jhy6t8znrmyskzldx0rzc6dw8bahne&ip=79.107.248.197&fields=country_flag,country_name,city,isp'
	# {"ip":"79.107.248.197","country_flag":"https://ipgeolocation.io/static/flags/gr_64.png","country_name":"Greece","city":"Thessaloniki","isp":"Tellas S.A"}

	# Retrive IP Info
	while read in; do abusecheck; echo $in | awk '{print $1}' | geolocation | awk -v var="$abusestatus" -F'["]' '{ print "|" $4 var "|{{" $8 "?32x32&cache}}|" $12 "|" $16 "|" $20 "|"}' >> $tmp.2; done < $tmp

	# Close TAG for Sortable Plugin
	echo "</sortable>" >> $tmp.2

	# Added Hits Number
	while read in; do sed -i -e 's/|'"$(echo $in  | awk '{print $2}')"'/'"$(echo $in  | awk '{print "|" $1 "|[[https:\/\/whois.domaintools.com\/" $2 "|W]] [[https:\/\/www.abuseipdb.com\/check\/" $2 "|A]]|[[gas:fail2ban:" $2 "|" $2 "]]"}')"'/g' $tmp.2; done < $tmp

	end=`date +%s`

	echo "//It took $(expr $end - $start) seconds to generate this list. Last update on $(date +"%Y-%m-%d")//" >> $tmp.2

	cat $tmp.2 > $dokuwikiReportFile

	# rm $tmp
	rm $tmp.2
}

createStatisticFile () {
	if [ -f "$resultsFile_day" ]; then

		cat $resultsFile_day $resultsFile_all | sort | uniq -c | sort -g -r | head -n "$topAmount" > $statisticFile

	else

		cat $resultsFile_day | sort | uniq -c | sort -g -r | head -n "$topAmount" > $statisticFile

	fi
}

# Search in fail2Ban for banned IPs
awk -F'[:]' '$2 >= '$fromTime' && $2 <= '$tillTime' { print }' $fail2banLogFile | grep Ban | grep -v ERROR | awk 'NF>1{print $NF}' | sort > $tmp

cat $tmp >> $resultsFile_day

addedToDokuwiki

reportIPs

createStatisticFile

if [ "$tillTime" == "23" ]; then

	cat $resultsFile_all >> $resultsFile_day
	cat $resultsFile_day | sort > $resultsFile_all
	rm $resultsFile_day

	createDokuWikiReport

fi

rm $tmp

exit 0

#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty
# 
# Please read more about at: https://gist.github.com/GAS85/a668b941f84c621a15ff581ae968e4cb

letsEncryptDirectory="/etc/letsencrypt/live/yourDomain"
apache2VirtualHostConfig="/etc/apache2/sites-enabled/YourVirtualHostConf.conf""

### End of configuration
show_help () {
echo "This script will fetch hash from the Letsencrypt Certificate and and put it into your Apache2 configuration.
Read more about on: https://gist.github.com/GAS85/a668b941f84c621a15ff581ae968e4cb
Syntax is publicKeyPinning.sh -h?d --dry-run
	-h, or ?	for this help
	-d	will only generate output without writting to the config
	--dry-run	is the same as -d
By Georgiy Sitnikov."
}

set -e

for i in "$@"; do
	case $i in
		-h|\?)
			show_help
			exit 0
		;;
		-d|--dry-run)
		dry=true
    	;;
	esac
done

# Check if you are root user
[[ $(id -u) -eq 0 ]] || { echo >&2 "You probably must be root to run this script."; exit 1; }

# Check if file exist
[[ -e $letsEncryptDirectory/cert.pem ]] || { echo >&2 "File ($letsEncryptDirectory/cert.pem) does't exist."; exit 1; }

# Check if file is writtable by Process
[[ -e $apache2VirtualHostConfig ]] || { echo >&2 "File ($apache2VirtualHostConfig) does't exist."; exit 1; }

# Check if file is writtable by Process
[[ -w $apache2VirtualHostConfig ]] || { echo >&2 "File ($apache2VirtualHostConfig) is not writable by process."; exit 1; }

# Calculating new hash of the file
hash1=$(cat $letsEncryptDirectory/cert.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

# Fetching current hash from the config
hash1_in_config=$(grep "Header always set Public-Key-Pins" $apache2VirtualHostConfig | awk -F'["]' '{ print $3 }' | rev | cut -c 2- | rev)

if [ "$dry" != "true" ]; then

	if [ "$hash1" != "$hash1_in_config" ]; then

		sed -i -e "s#$hash1_in_config#$hash1#g" $apache2VirtualHostConfig

		# Check Apache2 Config and reload the server
		apachectl configtest
		/bin/systemctl reload apache2 > null
	fi

else

	echo "Current Hash in Config"
    echo "	"$hash1_in_config
    echo "Hash from the certificate"
    echo "	"$hash1

fi

exit 0

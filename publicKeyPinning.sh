#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty

letsEncryptDirectory="/etc/letsencrypt/live/yourDomain"
apache2VirtualHostConfig="/etc/apache2/sites-enabled/YourVirtualHostConf.conf"

### End of configuration

set -e
hash1=$(cat $letsEncryptDirectory/cert.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
hash1_in_config=$(grep "Header always set Public-Key-Pins" /etc/apache2/sites-enabled/100-nextcloud.conf | awk -F'["]' '{ print $3 }' | rev | cut -c 2- | rev)

if [ "$hash1" != "$hash1_in_config" ]; then

	sed -i -e "s/$hash1_in_config/$hash1/g" $apache2VirtualHostConfig

	apachectl configtest && /bin/systemctl reload apache2 > null

fi

exit 0

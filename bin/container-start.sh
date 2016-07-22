#!/bin/bash

# Start apache
service apache2 start

if [[ ! -f /var/www/owncloud/config/config.php ]]
then
  mkdir -p /var/www/owncloud/config
  cp /root/config.php /var/www/owncloud/config/config.php
  chown -R www-data:www-data /var/www/owncloud
  echo "Installing"
  owncloud-config.sh
else
  occ upgrade --skip-migration-test --no-interaction
fi

su www-data -s /bin/bash -c "touch /mnt/data/owncloud.log"
tail -F /mnt/data/owncloud.log
#!/bin/bash

if [[ ! -f /var/www/owncloud/config/config.php ]]
then
  echo "Installing"

  mkdir -p /var/www/owncloud/config
  cp /root/config.php /var/www/owncloud/config/config.php
  chown -R www-data:www-data /var/www/owncloud

  owncloud-config.sh
else
  # offer backups here, optional

  echo "Updating"
  occ upgrade --skip-migration-test --no-interaction
fi

# Start apache
service apache2 start

# Start cron (todo)

su www-data -s /bin/bash -c "touch /mnt/data/owncloud.log"
tail -F /mnt/data/owncloud.log
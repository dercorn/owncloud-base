#!/bin/bash

if [[ ! -f /mnt/data/config/config.php ]]
then
  echo "Installing"
  rm -rf /var/www/owncloud/config
  cp /root/config.php /mnt/data/config/config.php
  ln -s /mnt/data/config /var/www/owncloud/config
  chown -R www-data:www-data /var/www/owncloud

  owncloud-config.sh
else
  # offer backups here, optional

  rm -rf /var/www/owncloud/config
  su www-data -s /bin/bash -c "ln -s /mnt/data/config /var/www/owncloud/config"

  echo "Update if needed"
  occ upgrade --skip-migration-test --no-interaction
fi

# Start apache
service apache2 start

# Start cron (todo)

su www-data -s /bin/bash -c "touch /mnt/data/files/owncloud.log"
tail -F /mnt/data/files/owncloud.log
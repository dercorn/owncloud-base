#!/bin/bash

# Volume could be empty, recreate folders
mkdir -p /mnt/data/config
mkdir -p /mnt/data/files
chown www-data:www-data /mnt/data/*

echo "waiting for infrastructure startup"
while ! ping -c1 mariadb &>/dev/null; do :; done
while ! mysql -h mariadb -u root -p$MARIADB_ENV_MARIADB_ROOT_PASSWORD -e "show databases" &>/dev/null; do :; done

if [[ ! -f /mnt/data/config/config.php ]]
then
  echo "Installing"
  rm -rf /var/www/owncloud/config
  cp /root/config.php /mnt/data/config/config.php
  ln -s /mnt/data/config /var/www/owncloud/config
  chown -R www-data.www-data /var/www/owncloud
  chown -R www-data.www-data /mnt/data/config

  owncloud-config.sh
else
  # offer backups here, optional

  rm -rf /var/www/owncloud/config
  ln -s /mnt/data/config /var/www/owncloud/config
  chown -R www-data.www-data /mnt/data/config
  
  echo "Update if needed"
  occ upgrade --skip-migration-test --no-interaction
fi

# Start apache
service apache2 start

# Start cron (todo)

su www-data -s /bin/bash -c "touch /mnt/data/files/owncloud.log"
tail -F /mnt/data/files/owncloud.log
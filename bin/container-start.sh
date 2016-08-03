#!/bin/bash

OWNCLOUD_DB_NAME=owncloud

function wait_for_db {
  echo "waiting for infrastructure startup"
  while ! ping -c1 mariadb &>/dev/null; do :; done
  while ! mysql -h mariadb -u root -p$MARIADB_ENV_MARIADB_ROOT_PASSWORD -e "show databases" &>/dev/null; do :; done
}

function create_folders {
  # Volume could be empty, recreate folders
  mkdir -p /mnt/data/config
  mkdir -p /mnt/data/files
  chown www-data:www-data /mnt/data/*
}

function link_config {
  echo "Linking shared config to instance"
  rm -rf /var/www/owncloud/config
  su www-data -s /bin/bash -c "ln -s /mnt/data/config /var/www/owncloud/config"
  chown -RL www-data:www-data /var/www/owncloud/config
}

function check_config {
  # Reading config parameter "installed"
  echo -n "Checking ownCloud config: "
  installed=$(occ -V | awk -F- '$1=="ownCloud is not installed "{print "false"}')
  [[ $installed == false ]] \
    && echo "No Config found - creating" \
    && cp /root/config.php /mnt/data/config/config.php \
    && link_config \
    || echo "Shared Config exists"; installed=true
}

function check_db {
  echo -n "ownCloud DB exists ($OWNCLOUD_DB_NAME): "
  db=$(mysql -h mariadb -u root -p$MARIADB_ENV_MARIADB_ROOT_PASSWORD -e "show databases" | grep $OWNCLOUD_DB_NAME)
  if [[ $db = $OWNCLOUD_DB_NAME ]]
  then
    echo "yes"
  else
    echo "no"
    [[ $installed == true ]] \
      && echo "--> resetting config" \
      && cp /root/config.php /mnt/data/config/config.php \
      && link_config \
      && installed=false
  fi
}

function check_connection {
  if [[ $installed == true ]]
  then
    echo -n "Checking DB connection: "
    occ status &>/dev/null
    [[ $? == 1 ]] \
      && echo "Connection Failed" \
      && installed=false \
      || echo "Connected"
  fi
}

wait_for_db
create_folders
link_config

check_config
check_db
check_connection

# ask ownCloud if status is installed
[[ $installed == true ]] \
  && installed=$(occ status |  awk -F":| " '$4=="installed"{print $6}')

echo -n "Installed $installed - "

if [[ $installed == true ]]
then
  version=$(occ status |  awk -F":| " '$4=="versionstring"{print $6}')
  edition=$(occ status |  awk -F":| " '$4=="edition"{print $6}')

  echo "Found ownCloud installation $edition $version"

  echo "Updating $edition $version to $(occ upgrade -V)"
  occ upgrade --skip-migration-test --no-interaction
else
  echo "Fresh install"

  echo -n "Checking ownCloud DB:"
  [[ $db = $OWNCLOUD_DB_NAME ]] && echo "ERROR: ownCloud DB already exists - Installation aborted" && exit 1 || echo "Ok"

  chown -RL www-data.www-data /var/www/owncloud

  owncloud-config.sh
fi

# Start apache
service apache2 start

# Start cron (todo)

su www-data -s /bin/bash -c "touch /mnt/data/files/owncloud.log"
tail -F /mnt/data/files/owncloud.log


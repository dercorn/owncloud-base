#!/bin/bash

XDEBUG_HOST=$1

echo "xdebug.remote_enable = 1" >> /etc/php/7.0/apache2/conf.d/20-xdebug.ini
[[ -n $XDEBUG_HOST ]] && echo "xdebug.remote_host = $XDEBUG_HOST" >> /etc/php/7.0/apache2/conf.d/20-xdebug.ini
[[ -z $XDEBUG_HOST ]] && echo "xdebug.remote_connect_back=1" >> /etc/php/7.0/apache2/conf.d/20-xdebug.ini

service apache2 restart

FROM owncloud/ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
  apache2 \
  libapache2-mod-php7.0 \
  php7.0-gd \
  php7.0-json \
  php7.0-mysql \
  php7.0-curl \
  php7.0-intl \
  php7.0-mcrypt \
  php-imagick \
  php7.0-zip \
  php7.0-xml \
  php7.0-mb \
  php-ldap \
  php-apcu \
  php-redis \
  smbclient \
  php-smbclient \
  mysql-client

# apache modules oc needs as documented
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod env
RUN a2enmod dir
RUN a2enmod mime
RUN a2enmod ssl
RUN a2ensite default-ssl

# Load php-libsmbclient
RUN echo "extension=smbclient.so" > /etc/php/7.0/cli/conf.d/20-smbclint.ini
RUN echo "extension=smbclient.so" > /etc/php/7.0/apache2/conf.d/20-smbclint.ini

# Upload of big files
RUN sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20G|' /etc/php/7.0/apache2/php.ini
RUN sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20G|' /etc/php/7.0/cli/php.ini
RUN sed -i 's|post_max_size = 8M|post_max_size = 20G|' /etc/php/7.0/apache2/php.ini
RUN sed -i 's|post_max_size = 8M|post_max_size = 20G|' /etc/php/7.0/cli/php.ini

# create folders
RUN mkdir -p /var/www/owncloud
RUN mkdir -p /mnt/data

RUN chsh -s /bin/bash www-data
RUN chown -R www-data.www-data /mnt/data

# Apache configs
RUN sed -i 's_DocumentRoot /var/www/html_DocumentRoot /var/www/owncloud_' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i 's_DocumentRoot /var/www/html_DocumentRoot /var/www/owncloud_' /etc/apache2/sites-enabled/default-ssl.conf
RUN sed -i 's|</VirtualHost>|\t<IfModule mod_headers.c>\n\t\t\tHeader always set Strict-Transport-Security "max-age=15768000; includeSubDomains; preload"\n\t\t</IfModule>\n\t</VirtualHost>|' /etc/apache2/sites-enabled/default-ssl.conf
RUN sed -i 's|unset HOME|unset HOME\nexport HOME=/var/www|' /etc/apache2/envvars
RUN mv /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/ssl-cert.pem
RUN mv /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert.key
RUN sed -i 's|ssl-cert-snakeoil.pem|ssl-cert.pem|' /etc/apache2/sites-enabled/default-ssl.conf
RUN sed -i 's|ssl-cert-snakeoil.key|ssl-cert.key|' /etc/apache2/sites-enabled/default-ssl.conf

# Base config
ADD conf/config.php /root/config.php

# Provide scripts in /usr/local/bin
ADD bin src/bin
RUN chmod 0755 src/bin/*
RUN cp src/bin/* /usr/local/bin

VOLUME /mnt/data

EXPOSE 443
EXPOSE 80

CMD ["bash", "container-start.sh"]

#!/bin/bash
if [ $# -ne 5 ]; then
	echo "Missing parameters; exiting"
	exit 1
fi

GROUP_ID=$1
GROUP_NAME=$2
USER_ID=$3
USER_NAME=$4
SITE_NAME=$5

# PHP7 is the default PHP version, so change /usr/bin/ph* if PHP5 is specified
if [[ "x$PHP_VERSION" =~ x5\.. && -x /usr/bin/php5 ]]; then
  rm -f /etc/alternatives/php /etc/alternatives/phar
  ln -s /usr/bin/php5 /etc/alternatives/php
  ln -s /usr/bin/phar5 /etc/alternatives/phar
fi

[ -z $COMPOSER_ARGS ] && export COMPOSER_ARGS='--prefer-dist --no-dev --optimize-autoloader'

groupadd -g $GROUP_ID $GROUP_NAME
useradd -u $USER_ID -g $GROUP_NAME $USER_NAME
chown -R $USER_NAME:$GROUP_NAME /etc/apache2
chown -R $USER_NAME:$GROUP_NAME /opt/Kudu
chown -R $USER_NAME:$GROUP_NAME /home
touch /var/log/apache2/kudu-error.log
touch /var/log/apache2/kudu-access.log
mkdir -p /var/lock/apache2 /var/run/apache2
chown -R $USER_NAME:$GROUP_NAME /var/log/apache2 /var/lock/apache2 /var/run/apache2
chown -R $USER_NAME:$GROUP_NAME /tmp
sed -i -- "s/KuduSite/$SITE_NAME/g" /etc/apache2/sites-available/kudu.conf
sed -i -- "s/user-placeholder/$USER_NAME/g" /etc/apache2/apache2.conf
sed -i -- "s/group-placeholder/$GROUP_NAME/g" /etc/apache2/apache2.conf
sed -i -- "s/80/8080/g" /etc/apache2/ports.conf
mkdir -p /etc/mono/registry
chmod uog+rw /etc/mono/registry
chown -R $USER_NAME:$GROUP_NAME /etc/mono/registry
cd /etc/apache2/sites-available
a2dissite 000-default.conf
a2ensite kudu.conf

#Run apache
/usr/sbin/apache2ctl -D FOREGROUND
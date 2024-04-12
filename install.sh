#!/bin/bash

ENV_FILE_PATH=/etc/apache2/envvars
WP_PATH=/var/www/html/wordpress
wget -P /home/ubuntu/  https://wordpress.org/latest.tar.gz
tar -xzvf /home/ubuntu/latest.tar.gz -C /home/ubuntu/
sudo apt-get update && sudo apt-get install -y apache2

sudo apt -y install php-all-dev && sudo apt -y install php-intl && sudo apt -y install php-mbstring libapache2-mod-php
sudo apt-get -y install php-mysql

sudo cp -r /home/ubuntu/wordpress /var/www/html/
wget -P /home/ubuntu/ https://gist.githubusercontent.com/Alexander198961/9504ea08f9cf8ab224b093fdc4bb4acc/raw/95fb670ab53286d8a84aa4caf20974d8d16001c8/wp-config.php
sudo cp /home/ubuntu/wp-config.php $WP_PATH

DB_REMOTE_HOST=`echo ${DB_HOST} | sed "s/:3306//g"`
function update(){
sudo echo "export DB_NAME=${DB_NAME}" >> $ENV_FILE_PATH
sudo echo "export DB_USERNAME=${DB_USERNAME}" >> $ENV_FILE_PATH
sudo echo "export DB_PASSWORD=${DB_PASSWORD}" >> $ENV_FILE_PATH
sudo echo "export DB_HOST=$DB_REMOTE_HOST" >> $ENV_FILE_PATH
sudo echo "export REDIS_ENDPOINT=${REDIS_ENDPOINT}" >> $ENV_FILE_PATH
sudo chown -R ubuntu:ubuntu  $WP_PATH/wp-content
}
update
ENV_FILE_PATH=~/.bashrc
update
wget -P /home/ubuntu/ https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /home/ubuntu/wp-cli.phar
sudo mv /home/ubuntu/wp-cli.phar /usr/local/bin/wp
source $ENV_FILE_PATH
DB_NAME=${DB_NAME} DB_USERNAME=${DB_USERNAME} DB_PASSWORD=${DB_PASSWORD} DB_HOST=$DB_REMOTE_HOST REDIS_ENDPOINT=${REDIS_ENDPOINT} /usr/local/bin/wp plugin install redis-cache  --path=$WP_PATH  --allow-root 2>&1 | tee -a  /tmp/out

DB_NAME=${DB_NAME} DB_USERNAME=${DB_USERNAME} DB_PASSWORD=${DB_PASSWORD} DB_HOST=$DB_REMOTE_HOST REDIS_ENDPOINT=${REDIS_ENDPOINT} /usr/local/bin/wp user create alex alexander198961@gmail.com --role=administrator   --path=$WP_PATH  --allow-root 2>&1 | tee -a /tmp/out

DB_NAME=${DB_NAME} DB_USERNAME=${DB_USERNAME} DB_PASSWORD=${DB_PASSWORD} DB_HOST=$DB_REMOTE_HOST REDIS_ENDPOINT=${REDIS_ENDPOINT} /usr/local/bin/wp plugin activate redis-cache  --path=$WP_PATH  --allow-root 2>&1 | tee -a /tmp/out
service apache2 restart

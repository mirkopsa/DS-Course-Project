#!/bin/bash

### The following commands were used to set up OpenEMR on cPouta

### Install MariaDB and Apache web server
sudo apt-get install apache2 mariadb-server libapache2-mod-php libtiff-tools php php-mysql php-cli php-gd php-xml php-curl php-soap php-json imagemagick php-mbstring php-zip php-ldap

### Download OpenEMR
sudo wget https://sourceforge.net/projects/openemr/files/OpenEMR%20Current/7.0.0/openemr-7.0.0.tar.gz

### Extract openemr and move it to /var/www/html for the webserver to access it
tar -xvzf openemr-7.0.0.tar.gz 
sudo mv openemr-7.0.0 /var/www/html/openemr

### Make sure permissions are set for correct access
sudo chmod -R 775 /var/www/html/openemr/
sudo chmod -R 666 /var/www/html/openemr/sites/default/sqlconf.php
sudo chown -R www-data:www-data /var/www/html/openemr/
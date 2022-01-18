#! /bin/sh

#######################################################################################################################################################
#                                                      CentOS 8 - Install and Configure Wordpress                                                     #
#                                                               Author - Richard Fletcher                                                             #
#                                                        E-mail: richard.p.fletcher@outlook.com                                                       #
#                                                               Version 1.4 - 18/01/2022                                                              #
#######################################################################################################################################################

#######################################################################################################################################################
#                                                               Installing EPEL Release                                                               #
#######################################################################################################################################################

echo -e "\e[1;34m Updating System with the lateste EPEL Release, please wait.... \e[0m"

{
yum -y install epel-release
yum update -y
} &> /dev/null

echo -e "\e[1;32m Updated Successfully! \e[0m"

#######################################################################################################################################################
#                                                                  Enabling PHP                                                                       #
#######################################################################################################################################################

echo -e "\e[1;34m Enabling remi-release and PHP 8.0, please wait....\e[0m"

{
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module list php -y
dnf module reset php -y 
dnf module enable php:remi-8.0 -y
} &> /dev/null

echo -e "\e[1;32m PHP Enabled Successfully! \e[0m"

#######################################################################################################################################################
#                                                             Install Pre-Requisites                                                                  #
#######################################################################################################################################################

echo -e "\e[1;34m Installing all required packages....\e[0m"

{
dnf install php php-cli php-common php-mysqlnd php-fpm mariadb-server httpd tar curl php-json php-gd -y
} &> /dev/null

echo -e "\e[1;32m Packages Installed Successfully! \e[0m"

#######################################################################################################################################################
#                                                                Configure Firewall                                                                   #
#######################################################################################################################################################

echo -e "\e[1;34m Opening ports 80/TCP and 443/TCP and restarting the firewall, please wait...\e[0m"

{
firewall-cmd --permanent --zone=public --add-service=http 
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
systemctl start mariadb
systemctl start httpd
systemctl enable mariadb
systemctl enable httpd
} &> /dev/null

echo -e "\e[1;32m Firewall ports opened and firewall restarted Successfully! \e[0m"

#######################################################################################################################################################
#                                                             MySQL Secure Installation                                                               #
#######################################################################################################################################################

echo -e "\e[1;34m Starting the MySQL Secure Installation...\e[0m"

echo -e "\e[1;36m Please enter a new SQL Root password:\e[0m"
read -s sqlpassword

mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('$sqlpassword') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

echo -e "\e[1;32m New SQL root set and MySQL Defaults Configured Sucessfully! \e[0m"

#######################################################################################################################################################
#                                                      Install Certbot and Request Certificate                                                        #
#######################################################################################################################################################

echo -e "\e[1;34m Installing Certbot and requesting user details...\e[0m"

echo -e "\e[1;36m Please enter the e-mail associated with this certificate:\e[0m"
read email
echo -e "\e[1;36m Please enter the root domain for this certificate:\e[0m"
read domain

echo -e "\e[1;33m Press ENTER when you have ensured you have 80/TCP open from the internet to this webserver!\e[0m"
read -p 'Press ENTER to continue'

{
dnf install certbot python3-certbot-apache mod_ssl -y
grep DocumentRoot /etc/httpd/conf.d/ssl.conf
} &> /dev/null

echo -e "\e[1;34m Creating the Let's Encrypt Certificate for your domain...\e[0m"

{
certbot certonly --webroot -w /var/www/html/ --renew-by-default --email $email --text --agree-tos  -d $domain -d www.$domain
} &> /dev/null

echo -e "\e[1;32m Certificate generated successfully! \e[0m"

#######################################################################################################################################################
#                                                     Inject Certificate files into SSL Conf                                                          #
#######################################################################################################################################################

echo -e "\e[1;34m Injecting certificate strings into /etc/httpd/conf.d/ssl.conf...\e[0m"

sed -Ei "s|SSLCertificateFile /etc/pki/tls/certs/localhost.crt|SSLCertificateFile /etc/letsencrypt/live/$domain/cert.pem|g" /etc/httpd/conf.d/ssl.conf
sed -Ei "s|SSLCertificateKeyFile /etc/pki/tls/private/localhost.key|SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem|g" /etc/httpd/conf.d/ssl.conf
sed -Ei "s|#SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt|SSLCertificateChainFile /etc/letsencrypt/live/$domain/fullchain.pem|g" /etc/httpd/conf.d/ssl.conf

echo -e "\e[1;32m Certificate installed Sucessfully and ssl.conf updated! \e[0m"

#######################################################################################################################################################
#                                                            Restart Apache Services                                                                  #
#######################################################################################################################################################

echo -e "\e[1;34m Restarting Apache services...\e[0m"

{
apachectl -t
systemctl restart httpd
} &> /dev/null

echo -e "\e[1;32m Services restarted Sucessfully! \e[0m"

#######################################################################################################################################################
#                                                          Configure Wordpress Database                                                               #
#######################################################################################################################################################

echo -e "\e[1;34m Starting the Wordpress database configuration..\e[0m"

echo -e "\e[1;36m Please enter the database name you would like to use (Press enter to use the default name:\e[1;31m wordpress)\e[0m"
read databasename
databasename="${databasename:=wordpress}"
echo -e "\e[1;32m Your database name has been set to\e[1;31m $databasename\e[0m"

echo -e "\e[1;36m Please enter the database user you would like to configure: (Press enter to use the default username:\e[1;31m wordpressuser)\e[0m"
read databaseuser
databaseuser="${databaseuser:=wordpressuser}"
echo -e "\e[1;32m Your database user has been set to\e[1;31m $databaseuser\e[0m"

echo -e "\e[1;36m Please enter the database password you would like to set:\e[0m"
read -s databasepassword

mysql -uroot -p$sqlpassword<<MYSQL_SCRIPT

CREATE DATABASE $databasename;
CREATE USER $databaseuser@localhost IDENTIFIED BY '$databasepassword';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost IDENTIFIED BY '$databasepassword';
FLUSH PRIVILEGES;
exit
MYSQL_SCRIPT

echo -e "\e[1;32m Database Configured Sucessfully! \e[0m"

#######################################################################################################################################################
#                                                              Installing Wordpress                                                                   #
#######################################################################################################################################################

echo -e "\e[1;34m Downloading and installing the latest version of Wordpress..\e[0m"

{
yum -y install wget
wget http://wordpress.org/latest.tar.gz
tar xfz latest.tar.gz 
cp -rf wordpress/* /var/www/html/
mkdir /var/www/html/wp-content/uploads
sudo chown -R apache:apache /var/www/html/*
ls /var/www/html/
cd /var/www/html
cp wp-config-sample.php wp-config.php
} &> /dev/null

echo -e "\e[1;32m Wordpress downloaded and installed sucessfully! \e[0m"

#######################################################################################################################################################
#                                                  Inject database configuration into wp-config.php                                                   #
#######################################################################################################################################################

echo -e "\e[1;34m Injecting database strings into /var/www/html/wp-config.php...\e[0m"

sed -Ei "s|database_name_here|$databasename|g" /var/www/html/wp-config.php
sed -Ei "s|username_here|$databaseuser|g" /var/www/html/wp-config.php
sed -Ei "s|password_here|$databasepassword|g" /var/www/html/wp-config.php

echo -e "\e[1;32m Database strings injected and wp-config.php updated! \e[0m"

#######################################################################################################################################################
#                                                      Inject PHP Configuration into php.ini                                                          #
#######################################################################################################################################################

echo -e "\e[1;36m Please enter the amount of memory you would like to limit PHP to (Press enter to use the default value:\e[1;31m 256M)\e[0m"
read memorylimit
memorylimit="${memorylimit:=256M}"
echo -e "\e[1;32m Your PHP memory limit has been set to\e[1;31m $memorylimit\e[0m"

echo -e "\e[1;36m Please enter the maximum file size limit you woud like to set for your site (Press enter to use the default value:\e[1;31m 100M)\e[0m"
read uploadsize
uploadsize="${uploadsize:=100M}"
echo -e "\e[1;32m Your file upload size has been set to\e[1;31m $uploadsize\e[0m"


echo -e "\e[1;34m Injecting PHP strings into /etc/php.ini...\e[0m"

sed -Ei "s|memory_limit = 128M|memory_limit = $memorylimit|g" /etc/php.ini
sed -Ei "s|post_max_size = 8M|post_max_size = $uploadsize|g" /etc/php.ini
sed -Ei "s|upload_max_filesize = 2M|upload_max_filesize = $uploadsize|g" /etc/php.ini

echo -e "\e[1;32m PHP.ini updated! \e[0m"

#######################################################################################################################################################
#                                                       Disabling SELINUX and restarting host                                                         #
#######################################################################################################################################################

echo -e "\e[1;34m Disabling SELINUX...\e[0m"

sed -Ei "s|SELINUX=enforcing|SELINUX=disabled|g" /etc/selinux/config

echo -e "\e[1;32m SELINUX Disabled! \e[0m"

echo -e "\e[1;42m Congratulations! Installation Complete! Press ENTER to restart. Once restarted navigate to http://SERVER-IP to setup Wordpress\e[0m"
read -p 'Press ENTER to continue'

sudo shutdown -r 0

#######################################################################################################################################################
#                                                                 End of Script                                                                       #
#######################################################################################################################################################

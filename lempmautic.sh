#!/bin/sh


checkerr()
{
if test $? -ne 0 ; then
echo error, something is wrong/ has failed!
echo failed step was :
echo "$@"
echo exiting ..
exit 1
fi
}


if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "###################################################"
echo "### CAUTION ### CAUTION ### CAUTION ### CAUTION ###"
echo "THIS INSTALLATION SHOULD BE DONE ON A CLEAN NEW SYSTEM ONLY."
echo "MANY SYSTEM FILES WILL BE ALTERED INCLUDING NGINX, NETWORK SETTINGS AND SO ON."
echo "AFTER INSTALLATION REVERT IS NOT POSSIBLE"
echo "###################################################"
echo "Please press enter to continue, or ctrl + c to exit"
read  -r aa
checkerr


##Read hostname  index index.html index.htm index.php; at /etc/nginx/sites-available/default

echo Please enter your host/domain for fresh installation only and press Enter.
echo if this is not fresh installation then press CTRL+c or the current system will be destroyed.
read -r mys

echo 'server {

        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;
        gzip on;
        location / {
                try_files $uri $uri/ =404;
        }

location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }


}' > tmp

mv tmp /etc/nginx/sites-available/$mys
ln -sf /etc/nginx/sites-available/$mys /etc/nginx/sites-enabled/$mys
mkdir -p /var/www/$mys
checkerr mkdir -p /var/www/$mys
sed -i "s/\/var\/www\/html/\/var\/www\/$mys/g"  /etc/nginx/sites-available/$mys
sed -i "s/server_name\ _/server_name\ $mys www.$mys/g"  /etc/nginx/sites-available/$mys

certbot --nginx -d "$mys" -d "www.$mys" --register-unsafely-without-email --agree-tos -n # can use -m for email
checkerr certbot --nginx -d "$mys" -d "www.$mys" --register-unsafely-without-email --agree-tos -n
nginx -t
checkerr

systemctl reload nginx
checkerr


#chown -R ftpman:www-data /var/www/

## Check root and os

apt-get update ; apt-get -y install nginx php-curl curl mysql-server

useradd -d /var/www/html/ -G www-data ftpman
chown -R ftpman:www-data /var/www/
checkerr
echo "ftpman:$mys" | chpasswd
checkerr echo "ftpman:$mys" '| chpasswd'
sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart
checkerr /etc/init.d/ssh restart
add-apt-repository ppa:certbot/certbot -y
checkerr add-apt-repository ppa:certbot/certbot -y
apt-get update
apt-get install python-certbot-nginx -y
#sed -i "s/server_name\ _/server_name\ $mys/g"  /etc/nginx/sites-available/default
##check nginx syntax
nginx -t
checkerr nginx -t

systemctl reload nginx
checkerr
ufw allow 'Nginx Full'
#ufw delete allow 'Nginx HTTP'

#certbot --nginx -d "$mys" --register-unsafely-without-email --agree-tos -n # can use -m for email
#checkerr certbot --nginx -d "$mys" --register-unsafely-without-email --agree-tos -n

sb=`grep -n 'server {' /etc/nginx/sites-available/default | grep -v '#' | head -n 1 | cut -f1 -d":"`
sb=`expr $sb + 3`
#ssl_dhparam /etc/ssl/certs/dhparam.pem;
sed -i  "$sb i\
gzip on;\\
" /etc/nginx/sites-available/default
checkerr
#sed -i 's/#\ listen\ 443/listen\ 443/g' /etc/nginx/sites-available/default
#sed -i 's/#\ listen\ \[\:\:\]\:443/listen\ \[\:\:\]\:443/g' /etc/nginx/sites-available/default
nginx -t
checkerr nginx -t


systemctl reload nginx
checkerr

echo '15 3 * * * /usr/bin/certbot renew --quiet' > autorenew
crontab autorenew
checkerr
rm -rf autorenew


chown -R ftpman:www-data /var/www/
# add this
chown -R  ftpman:ftpman /var/www/
apt-get update ; apt-get -y upgrade --force-yes

#apt-get install php-fpm php-mysql -y
apt-get install -y --force-yes php7.0-fpm php7.0-cli php7.0-dev \
php-sqlite3 php-gd \
php-curl php7.0-dev \
php-imap php-mysql php-memcached php-mcrypt php-mbstring \
php-xml php-imagick php7.0-zip php7.0-bcmath php-soap \
php7.0-intl php7.0-readline
echo 'cgi.fix_pathinfo=0' >> /etc/php/7.0/cli/php.ini

# Misc. PHP CLI Configuration

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini


systemctl restart php7.0-fpm

sb=`grep -n 'server {' /etc/nginx/sites-available/default | grep -v '#' | head -n 1 | cut -f1 -d":"`
sb=`expr $sb + 3`
#ssl_dhparam /etc/ssl/certs/dhparam.pem;
sed -i  "$sb i\
  location ~ \\.php\$ {\\
                include snippets/fastcgi-php.conf;\\
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;\\
        }\\
" /etc/nginx/sites-available/default
checkerr

#mautic installation
cd /var/www/$mys/
sudo wget https://www.mautic.org/download/latest 
unzip latest -d mautic
sudo chown -R www-data:www-data /var/www/mautic/


nginx -t
checkerr nginx -t
systemctl restart nginx


echo "######################################################################"
echo "CONGRATULATIONS ! INSTALLATION IS READY, YOU MAY LOGIN TO SFTP SERVICE"
echo "######################################################################"

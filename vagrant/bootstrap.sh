echo "Provisioning..."

echo "---------------------------------------------------------------------------------------------"
echo "Updating box..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade


echo "---------------------------------------------------------------------------------------------"
echo "[PHP5] Adding Repository & Tools..."
add-apt-repository ppa:ondrej/php -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update

echo "[PHP5] Installing..."
apt-get install -y libapache2-mod-php5.6 php5.6 php5.6-json

echo "[PHP5] Linking config..."
if ! [ -L /etc/php ]; then
  sudo cp -r /etc/php /vagrant/vagrant/config
  sudo rm -rf /etc/php
  sudo ln -fs /vagrant/vagrant/config/php /etc/php
fi

# Patch pour configurer le PHP correctement
cp -f /vagrant/vagrant/config.alt/php/5.6/apache2/conf.d/php.ini /etc/php/5.6/apache2/conf.d/php.ini

echo "---------------------------------------------------------------------------------------------"
echo "[APACHE] Installing..."
apt-get install -y apache2 apache2-utils
a2enmod rewrite

echo "[APACHE] Linking config..."
if ! [ -L /var/www ]; then
  sudo cp -r /etc/apache2 /vagrant/vagrant/config
  sudo rm -rf /etc/apache2
  sudo ln -fs /vagrant/vagrant/config/apache2 /etc/apache2
fi

# Patch pour linker correctement la racine web
cp -f /vagrant/vagrant/config.alt/apache2/sites-enabled/000-default.conf /etc/apache2/sites-available/000-default.conf

sudo service apache2 restart


echo "---------------------------------------------------------------------------------------------"
echo "[MYSQL] Preparing..."
apt-get install -y debconf-utils
debconf-set-selections <<< "mysql-server mysql-server/root_password password devnci"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password devnci"

echo "[MYSQL] Installing MySQL..."
apt-get install -y mysql-server mysql-client

echo "[MYSQL] Linking config..."
if ! [ -L /etc/mysql ]; then
  sudo cp -r /etc/mysql /vagrant/vagrant/config
  sudo rm -rf /etc/mysql
  sudo ln -fs /vagrant/vagrant/config/mysql /etc/mysql
fi

# Patch apparmor pour pouvoir utiliser mysql avec les fichiers de configuration déportés
cp -f /vagrant/vagrant/config.alt/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/usr.sbin.mysqld
service mysql restart

echo "---------------------------------------------------------------------------------------------"
echo "[FREETDS] Installing..."
apt-get install -y php5.6-sybase freetds-common

echo "[FREETDS] Linking config..."
if ! [ -L /etc/freetds ]; then
  sudo cp -r /etc/freetds /vagrant/vagrant/config
  sudo rm -rf /etc/freetds
  sudo ln -fs /vagrant/vagrant/config/freetds /etc/freetds
fi

# Patch pour mettre en place les bons liens freetds
cp -f /vagrant/vagrant/config.alt/freetds/freetds.conf /etc/freetds/freetds.conf
cp -f /vagrant/vagrant/config.alt/freetds/locales.conf /etc/freetds/locales.conf

echo "---------------------------------------------------------------------------------------------"
echo "[PHPMYADMIN] Installing..."
debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password devnci'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password devnci'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password devnci'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'
apt-get install -y phpmyadmin php5.6-mbstring php-gettext php5.6-mysqli php5.6-mcrypt

echo "[PHPMYADMIN] Linking config..."
if ! [ -L /etc/phpmyadmin ]; then
  sudo cp -r /etc/phpmyadmin /vagrant/vagrant/config
  sudo rm -rf /etc/phpmyadmin
  sudo ln -fs /vagrant/vagrant/config/phpmyadmin /etc/phpmyadmin
fi

echo "---------------------------------------------------------------------------------------------"
echo "[FINISH] Cleaning things"
service apache2 restart
apt-get -y autoremove

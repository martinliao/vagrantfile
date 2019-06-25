#!/bin/bash

MODVER=31
MODPORT=80
MODEMAIL=martin@click-ap.com

# Full unicode support, https://docs.moodle.org/35/en/MySQL_full_unicode_support
sudo sed -i 's|\[mysqld\]|&\nskip-character-set-client-handshake|' /etc/my.cnf
sudo sed -i 's|\[mysqld\]|&\ncollation-server = utf8mb4_unicode_ci|' /etc/my.cnf
sudo sed -i 's|\[mysqld\]|&\ncharacter-set-server = utf8mb4|' /etc/my.cnf
sudo sed -i 's|\[mysqld\]|&\ninnodb_large_prefix|' /etc/my.cnf
sudo sed -i 's|\[mysqld\]|&\ninnodb_file_per_table = 1|' /etc/my.cnf
sudo sed -i 's|\[mysqld\]|&\ninnodb_file_format = Barracuda|' /etc/my.cnf

# append text to a write protected file
echo -e "[mysql]\ndefault-character-set = utf8mb4\n"  | sudo tee -a /etc/my.cnf
sudo sed -i 's|\[client\]|&\ndefault-character-set = utf8mb4|' /etc/my.cnf.d/client.cnf

sudo systemctl start mariadb

mysql -u root mysql <<EOF
    UPDATE mysql.user SET Password=PASSWORD('jack5899') WHERE User='root';
    FLUSH PRIVILEGES;
EOF

# download moodle from web
wget https://download.moodle.org/download.php/direct/stable$MODVER/moodle-latest-$MODVER.tgz
sudo tar zxf moodle-latest-$MODVER.tgz -C /var/www/html # remark v: verbose
sudo mkdir /var/www/moodledata
sudo chown vagrant:apache -R /var/www/html/$WEBDIR /var/www/moodledata
cd /var/www/html/$WEBDIR
php admin/cli/install.php --agree-license --non-interactive --lang=en --wwwroot=http://localhost:$MODPORT/$WEBDIR --dataroot=/var/www/moodledata --dbtype=mariadb --dbhost=localhost --dbname=$WEBDIR --dbuser=root --dbpass=jack5899 --fullname=Moodle$MODVER-lst --shortname=Mod$MODVERlst --adminpass=Jack5899! --adminemail=$MODEMAIL

# add $CFG->cachejs, Prevent JS caching
sudo sed -i '/$CFG->admin/a $CFG->debugdisplay = 1;' config.php
sudo sed -i '/$CFG->admin/a $CFG->debug = (E_ALL | E_STRICT);' config.php
sudo sed -i '/$CFG->admin/a $CFG->cachejs   = false;' config.php
sudo sed -i '/$CFG->admin/a $CFG->yuicomboloading = false;' config.php
#sudo chown apache -R /var/www/html/moodle /var/www/moodledata
sudo chown apache /var/www/html/$WEBDIR/config.php
#sudo chmod 440 /var/www/html/$WEBDIR/config.php

sudo systemctl restart httpd

sudo chown -R vagrant:apache /var/www/html/$WEBDIR
echo "Apache restart OK."

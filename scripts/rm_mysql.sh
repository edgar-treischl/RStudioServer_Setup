sudo apt install mysql-server
sudo mysql_secure_installation

#sudo apt purge mysql-server

sudo systemctl stop mysqld

sudo apt purge mysql-server mysql-common mysql-server-core-* mysql-client-core-*

sudo rm -rf /var/lib/mysql/

sudo rm -rf /etc/mysql/

sudo rm -rf /var/log/mysql

sudo deluser --remove-home mysql

sudo delgroup mysql



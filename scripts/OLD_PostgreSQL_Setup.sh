#!/bin/bash

#ssh root@ip_address




adduser edgar
usermod -aG sudo edgar


#ssh root@ip_address




#adduser rstudio

#sudo apt install certbot python3-certbot-nginx





#Install PostgreSQL and the PostgreSQL client libraries:
sudo apt install postgresql postgresql-contrib

#Check the status of the PostgreSQL service:
sudo systemctl status postgresql


#Maintenance Commands
#sudo systemctl start postgresql
sudo systemctl enable postgresql

#Switch to PostgreSQL userl
sudo -i -u postgres

#Access PostgreSQL Command Line
psql

#SQL
CREATE DATABASE defaultdb;

#Verify that the database was created by listing all the databases
\l

#Create a new user
CREATE USER edgar WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO edgar;

\du

\q







#Allow Remote Connections 

#Edit postgresql.conf to listen on all IP addresses:
#set: listen_addresses = '*'

psql --version

sudo nano /etc/postgresql/16/main/postgresql.conf


#Configure pg_hba.conf for remote access:
sudo nano /etc/postgresql/16/main/pg_hba.conf

#Add line
#host    all             all             0.0.0.0/0            md5


#Restart PostgreSQL to apply changes:
sudo systemctl restart postgresql


#Allow PostgreSQL Port through the Firewall (Optional)
sudo ufw status

#Allow PostgreSQL port
sudo ufw allow 5432/tcp

#Set up a password for the postgres user
sudo -i -u postgres
psql
ALTER USER postgres WITH PASSWORD 'password';

\q
exit



#sudo apt install pgadmin4

sudo apt install curl ca-certificates gnupg
curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo tee /etc/apt/trusted.gpg.d/packages_pgadmin_org.asc

sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/ubuntu/ focal pgadmin4" > /etc/apt/sources.list.d/pgadmin4.list'

sudo apt update

sudo apt install pgadmin4-web


#Website:
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

sudo apt install pgadmin4

sudo /usr/pgadmin4/bin/setup-web.sh

edgar.treischl@me.com


sudo apt install apache2

sudo nano /etc/apache2/apache2.conf



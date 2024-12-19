adduser gisela
usermod -aG sudo gisela


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
CREATE USER gisela WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO gisela;

\du

\q


\c defaultdb

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gisela;





#Allow Remote Connections 

#Edit postgresql.conf to listen on all IP addresses:
#set: listen_addresses = '*'



sudo nano /etc/postgresql/12/main/postgresql.conf


#Configure pg_hba.conf for remote access:
sudo nano /etc/postgresql/12/main/pg_hba.conf

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






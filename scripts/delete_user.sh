echo "Creating a default PostgreSQL role and database..."
#sudo -u postgres psql -c "CREATE USER edgar WITH PASSWORD 'Hase';"
sudo -u postgres psql -c "CREATE DATABASE default_db WITH OWNER edgar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE default_db TO edgar;"


sudo -i -u postgres

psql

#ALTER USER postgres WITH PASSWORD 'Hase';

\q



#DEL Stefan
#!/bin/bash

# 1. Revoke all privileges from stefan
# Revoke any privileges on the 'public' schema for 'stefan'
sudo -u postgres psql -d default_db -c "REVOKE ALL PRIVILEGES ON SCHEMA public FROM edgar;"

# Revoke any privileges on the database for 'stefan'
sudo -u postgres psql -d default_db -c "REVOKE ALL PRIVILEGES ON DATABASE default_db FROM edgar;"

# Revoke default privileges on tables in the 'public' schema
sudo -u postgres psql -d default_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM edgar;"

# Revoke default privileges on sequences in the 'public' schema
sudo -u postgres psql -d default_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM edgar;"


#sudo -u postgres psql -c "REVOKE ALL ON SCHEMA public FROM victoria;"

sudo -u postgres psql -d default_db -c "REASSIGN OWNED BY edgar TO treischl;"

sudo -u postgres psql -d default_db -c "DROP OWNED BY edgar CASCADE;"

sudo -u postgres psql -c "DROP ROLE IF EXISTS edgar;"





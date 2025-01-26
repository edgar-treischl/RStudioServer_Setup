# Add a new user
# sudo adduser treischl
# sudo usermod -aG sudo treischl
# su - treischl
# sudo whoami

#http://ip/pgadmin4


#!/bin/bash

# SSH into remote server

#ssh root@ip



# Update package list and upgrade any existing packages
echo "Updating package lists and upgrading existing packages..."
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL and its dependencies
echo "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Verify if PostgreSQL installation is successful
echo "Checking PostgreSQL installation..."
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL installation failed. Exiting."
    exit 1
else
    echo "PostgreSQL installed successfully."
fi

# Start PostgreSQL service and enable it to start on boot
echo "Starting PostgreSQL service..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Check if PostgreSQL is running
echo "Checking PostgreSQL service status..."
if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL service is not running. Exiting."
    exit 1
else
    echo "PostgreSQL is running."
fi

# NEW Superuser
# Set up a default PostgreSQL database and user (optional)
#sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE pgadmin TO pgadminuser;"
echo "Creating a default PostgreSQL role and database..."
sudo -u postgres psql -c "CREATE USER treischl WITH SUPERUSER PASSWORD 'EnterPassword';"
sudo -u postgres psql -c "CREATE DATABASE default_db WITH OWNER treischl;"


# Add pgAdmin 4 official repository and install pgAdmin 4
echo "Adding pgAdmin 4 repository..."
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

# Install pgAdmin 4
echo "Installing pgAdmin 4..."
sudo apt install -y pgadmin4-web

# Set up pgAdmin 4 web mode
echo "Setting up pgAdmin 4 web interface..."
export PGADMIN_DEFAULT_EMAIL="admin@example.com"
export PGADMIN_DEFAULT_PASSWORD="EnterPassword"
sudo /usr/pgadmin4/bin/setup-web.sh

# Configure PostgreSQL to listen on all IP addresses
echo "Configuring PostgreSQL to listen on all IP addresses..."
PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
echo "PostgreSQL version detected: $PG_VERSION"

# Modify postgresql.conf to allow listening on all IPs
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf

# Add necessary lines to pg_hba.conf for local and remote connections
echo "Configuring pg_hba.conf for local and remote connections..."

# Allow local connections with md5 authentication
echo "local   all             all                                     md5" | sudo tee -a /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Allow remote connections from any IP address with md5 authentication
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Restart PostgreSQL to apply configuration changes (after postgresql.conf and pg_hba.conf updates)
echo "Restarting PostgreSQL to apply configuration changes..."
sudo systemctl restart postgresql

# Check if UFW is active and allow the PostgreSQL port
if command -v ufw &> /dev/null; then
    sudo ufw status | grep -q "active"
    if [ $? -eq 0 ]; then
        sudo ufw allow 5432/tcp
    else
        echo "UFW is not active, skipping firewall configuration."
    fi
else
    echo "UFW is not installed, skipping firewall configuration."
fi

# Testing connection (local)
psql -h localhost -U treischl -d pgadmin -p 5432

# Troubleshooting
sudo -u postgres psql -c "\l"



# postgis?############################################
# We are running
pg_lsclusters

# Postgis is available for 
sudo apt search postgresql-16 | grep postgis

# Install
sudo apt install -y postgresql-16-postgis-3

# Verify PostGIS Installation
psql -U treischl -d default_db

# Create Extenstions for default_db
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster; 

SELECT PostGIS_Version();
SELECT * FROM pg_extension WHERE extname = 'postgis_raster';




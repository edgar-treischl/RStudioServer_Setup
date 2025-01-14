#!/bin/bash

# SSH into remote server (if required)

ssh root@ip

http://ip/pgadmin4





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

# Set up a default PostgreSQL database and user (optional)
echo "Creating a default PostgreSQL role and database..."
sudo -u postgres psql -c "CREATE USER pgadminuser WITH PASSWORD 'pgadminpassword';"
sudo -u postgres psql -c "CREATE DATABASE pgadmin WITH OWNER pgadminuser;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE pgadmin TO pgadminuser;"



# Add pgAdmin 4 official repository and install pgAdmin 4
echo "Adding pgAdmin 4 repository..."
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

# Install pgAdmin 4
echo "Installing pgAdmin 4..."
sudo apt install -y pgadmin4-web

# Set up pgAdmin 4 web mode
echo "Setting up pgAdmin 4 web interface..."
sudo /usr/pgadmin4/bin/setup-web.sh


# Edit postgresql.conf to listen on all IP addresses
sudo nano /etc/postgresql/16/main/postgresql.conf

#New


# Edit postgresql.conf to listen on all IP addresses
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf


# Add line to allow remote connections
echo "host    all             all             0.0.0.0/0            md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf

# --- 5. Restart PostgreSQL to apply changes ---
echo "Restarting PostgreSQL to apply configuration changes..."
sudo systemctl restart postgresql

# --- 6. Allow PostgreSQL through the firewall ---

# Check if UFW is active and allow the PostgreSQL port
sudo ufw status | grep -q "active"
if [ $? -eq 0 ]; then
    sudo ufw allow 5432/tcp
else
    echo "UFW is not active, skipping firewall configuration."
fi






psql -h localhost -U pgadminuser -d pgadmin -p 5432


sudo -u postgres psql -c "\l"




#Troubleshooting
# Install Apache and necessary modules for pgAdmin 4
#echo "Installing Apache and required modules..."
#sudo apt install -y apache2 libapache2-mod-wsgi-py3

# Enable required Apache modules
#echo "Enabling Apache modules..."
#sudo a2enmod cgi
#sudo a2enmod wsgi

# Ensure Apache is running
#echo "Checking Apache service status..."
#if ! systemctl is-active --quiet apache2; then
#    echo "Apache service is not running. Starting Apache."
#    sudo systemctl start apache2
#fi

# Disable default site and enable pgAdmin 4 site configuration
#echo "Configuring Apache for pgAdmin 4..."

# Create Apache configuration file for pgAdmin 4
# echo "Creating pgAdmin 4 Apache configuration file..."
# sudo bash -c 'cat <<EOL > /etc/apache2/sites-available/pgadmin4.conf
# <VirtualHost *:80>
#     ServerAdmin webmaster@localhost
#     DocumentRoot /usr/pgadmin4/web
# 
#     WSGIDaemonProcess pgadmin4 processes=1 threads=5 display-name=%{GROUP} python-home=/usr/pgadmin4/venv
#     WSGIProcessGroup pgadmin4
#     WSGIScriptAlias /pgadmin4 /usr/pgadmin4/web/pgAdmin4.wsgi
# 
#     ErrorLog \${APACHE_LOG_DIR}/error.log
#     CustomLog \${APACHE_LOG_DIR}/access.log combined
# 
#     <Directory /usr/pgadmin4/web>
#         Require all granted
#     </Directory>
# </VirtualHost>
# EOL'

# Enable the new site configuration for Apache
# echo "Enabling pgAdmin 4 site configuration..."
# sudo a2ensite pgadmin4.conf
# systemctl reload apache2

# Disable the default site (if enabled)
# echo "Disabling default site configuration..."
# sudo a2dissite 000-default.conf

# Test Apache configuration for errors
# echo "Testing Apache configuration..."
# sudo apache2ctl configtest


# Restart Apache to apply changes
# sudo systemctl restart apache2



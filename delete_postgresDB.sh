#!/bin/bash



# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo."
    exit 1
fi

echo "Starting uninstallation process..."

# 1. Remove PostgreSQL user and database (while PostgreSQL is still running)
echo "Removing PostgreSQL user and database..."
# First, ensure PostgreSQL is running before trying to drop the database and user
if systemctl is-active --quiet postgresql; then
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS pgadmin;"
    sudo -u postgres psql -c "DROP USER IF EXISTS pgadminuser;"
else
    echo "PostgreSQL is not running, skipping database/user removal."
fi

# 2. Stop and disable PostgreSQL service
echo "Stopping and disabling PostgreSQL service..."
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 3. Remove PostgreSQL and its dependencies
echo "Removing PostgreSQL and dependencies..."
sudo apt-get remove --purge -y postgresql postgresql-contrib
sudo apt-get autoremove --purge -y
sudo apt-get clean
sudo apt autoremove

# 4. Remove pgAdmin 4
echo "Removing pgAdmin 4..."
sudo apt-get remove --purge -y pgadmin4 pgadmin4-web
sudo apt-get autoremove --purge -y

# 5. Remove pgAdmin repository and associated files
echo "Removing pgAdmin repository and keys..."
sudo rm -f /etc/apt/sources.list.d/pgadmin4.list
sudo rm -f /usr/share/keyrings/packages-pgadmin-org.gpg

# 6. Remove PostgreSQL configuration changes
echo "Restoring PostgreSQL configuration files..."
PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
# Revert changes in postgresql.conf
sudo sed -i "s/listen_addresses = '*'/#listen_addresses = 'localhost'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf
# Revert changes in pg_hba.conf (remove remote access line)
sudo sed -i "/host    all             all             0.0.0.0\/0               md5/d" /etc/postgresql/$PG_VERSION/main/pg_hba.conf
sudo sed -i "/local   all             all                                     md5/d" /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# 7. Remove PostgreSQL service files (optional)
echo "Removing PostgreSQL service files..."
sudo rm -rf /etc/postgresql
sudo rm -rf /var/lib/postgresql
sudo rm -rf /var/log/postgresql

# 8. Check if UFW (Uncomplicated Firewall) is active and remove the PostgreSQL rule
if command -v ufw &> /dev/null; then
    echo "Checking UFW rules and removing PostgreSQL rule..."
    if sudo ufw status | grep -q "active"; then
        sudo ufw delete allow 5432/tcp
    fi
else
    echo "UFW is not installed, skipping firewall rule removal."
fi


# 9. Clean up any residual packages or cached data
echo "Cleaning up residual packages..."

# Remove any leftover PostgreSQL client, server development packages, and common files.
sudo apt-get remove --purge -y postgresql-client postgresql-common postgresql-server-dev-all

# Clean up the local package cache to free up space. This will remove all .deb files downloaded for packages.
sudo apt-get clean

# Automatically remove any packages that were installed as dependencies but are no longer needed.
sudo apt-get autoremove --purge -y

# Remove the PostgreSQL data directory if it exists. This directory contains databases, logs, etc.
# Be careful with this command, as it will completely delete PostgreSQL data.
sudo rm -rf /var/lib/postgresql

# Check if any PostgreSQL-related packages are still installed on the system. 
# If any are left, they will show up here.
dpkg -l | grep postgres

# In case specific versions of PostgreSQL client or common packages were installed, remove them explicitly.
# The version numbers should match the specific PostgreSQL version installed on your system.
sudo apt-get remove --purge -y postgresql-client-16 postgresql-client-common



# 10. Verify if PostgreSQL and pgAdmin are removed
echo "Verifying if PostgreSQL is uninstalled..."
if command -v psql &> /dev/null; then
    echo "PostgreSQL is still installed."
else
    echo "PostgreSQL has been uninstalled."
fi

echo "Verifying if pgAdmin 4 is uninstalled..."
if dpkg -l | grep -q pgadmin4; then
    echo "pgAdmin 4 is still installed."
else
    echo "pgAdmin 4 has been uninstalled."
fi

echo "Uninstallation process completed."

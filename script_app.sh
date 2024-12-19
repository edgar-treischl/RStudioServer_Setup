#!/bin/bash

#ssh root@ip


# Update system
apt-get update || { echo 'ERROR: apt-get update failed' >&2; exit 1; }
apt-get upgrade -y || { echo 'ERROR: apt-get upgrade failed' >&2; exit 1; }

# Install dependencies
#libfreetype6-dev is deprecated or no longer available in your distribution's repositories, so apt-get automatically selects the libfreetype-dev package as an alternative. This is usually fine, as both packages are typically related to FreeType (for font rendering).
#You can safely continue using libfreetype-dev unless you specifically need libfreetype6-dev for compatibility reasons, which is rare.
#pandoc-citeproc: With Pandoc now using the citeproc library internally => pandoc-citeproc no more needed, only pandoc

apt-get install -y gdebi-core libssl-dev libcurl4-openssl-dev libxml2-dev default-jdk fail2ban nginx libsodium-dev libpq-dev libopenblas-dev pandoc texlive-full libfreetype-dev libfontconfig1-dev




# Add R repository
#What is happening here: Line 1 and 2
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu 22.04-cran40/"
apt-get update
apt-get install -y r-base r-base-dev

# Install RStudio Server: ERROR NO FILE DOWNLOADED
# RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://download2.rstudio.org/server/jammy/amd64/VERSION)
# wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_LATEST}-amd64.deb
# gdebi -n rstudio-server-${RSTUDIO_LATEST}-amd64.deb
# rm rstudio-server-*-amd64.deb

# Specify the version directly
RSTUDIO_VERSION="2024.09.1-394"
# Construct the download URL using the specified version
wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb
# Install the RStudio Server .deb package
sudo gdebi -n rstudio-server-${RSTUDIO_VERSION}-amd64.deb
# Clean up the downloaded .deb file
rm rstudio-server-${RSTUDIO_VERSION}-amd64.deb



# Install Pak, Shiny and Shiny Server: replaced link
R -e "install.packages('pak', repos='https://cran.rstudio.com/')"
R -e "pak::pkg_install('shiny', repos='https://cran.rstudio.com/')"

wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
gdebi -n shiny-server-*-amd64.deb
rm shiny-server-*.deb

# Ensure Shiny app directory exists with correct permissions
mkdir -p /srv/shiny-server
chown -R shiny:shiny /srv/shiny-server
chmod -R 755 /srv/shiny-server

# Configure logging directories and permissions
mkdir -p /var/log/rstudio
mkdir -p /var/log/shiny-server
touch /var/log/rstudio/rserver-http-access.log
touch /var/log/shiny-server/shiny-server.log
chown -R rstudio-server:rstudio-server /var/log/rstudio
chown -R shiny:shiny /var/log/shiny-server

sudo mkdir -p /var/log/rstudio
sudo chown -R rstudio-server:rstudio-server /var/log/rstudio

# Configure RStudio Server logging
# cat > /etc/rstudio/logging.conf <<EOL
# [@access]
# log-level=info
# logger-type=file
# path=/var/log/rstudio/rserver-http-access.log
# EOL

# Configure Shiny Server logging: DEL server_log no longer supported
cat > /etc/shiny-server/shiny-server.conf <<EOL
# Define the user we should use when spawning R Shiny processes
run_as shiny;

# Define a top-level server which will listen on a port
server {
  listen 3838;

  # Define the location available at the base URL
  location / {
    site_dir /srv/shiny-server;
    log_dir /var/log/shiny-server;
    directory_index on;
  }
}

# Configure logging
preserve_logs true;
access_log /var/log/shiny-server/access.log;  # Logging access requests
log_dir /var/log/shiny-server;
EOL




# Configure logrotate for Shiny Server
cat > /etc/logrotate.d/shiny-server <<EOL
/var/log/shiny-server/*.log {
    rotate 7
    daily
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        systemctl reload shiny-server > /dev/null 2>/dev/null || true
    endscript
    create 0644 shiny shiny
}
EOL

# Test Shiny Server configuration
if ! systemctl restart shiny-server; then
    echo 'ERROR: Shiny Server failed to restart with new configuration' >&2
    exit 1
fi

# Verify log files are being written
# sleep 2
# if [ ! -f /var/log/shiny-server/server.log ]; then
#     echo 'WARNING: Shiny Server log file not created' >&2
# fi

sleep 2
if [ ! -f /var/log/shiny-server/access.log ]; then
    echo 'WARNING: Shiny Server access log file not created' >&2
fi

# Configure Fail2ban for RStudio and Shiny Server
cat > /etc/fail2ban/jail.local <<EOL
[rstudio-server]
enabled = true
port = 8787
filter = rstudio-server
logpath = /var/log/rstudio/rserver-http-access.log
maxretry = 3
bantime = 3600

[shiny-server]
enabled = true
port = 3838
filter = shiny-server
logpath = /var/log/shiny-server.log
maxretry = 3
bantime = 3600
EOL

cat > /etc/fail2ban/filter.d/rstudio-server.conf <<EOL
[Definition]
failregex = ^.*Failed login attempt for user .* from IP <HOST>.*$
ignoreregex =
EOL

cat > /etc/fail2ban/filter.d/shiny-server.conf <<EOL
[Definition]
# Detect failed authentication attempts
failregex = ^.*Error in auth.: .* \[ip: <HOST>\].*$
            ^.*Unauthenticated request: .* \[ip: <HOST>\].*$
            ^.*Invalid authentication request from <HOST>.*$
            ^.*Authentication error for .* from <HOST>.*$
            ^.*Failed authentication attempt from <HOST>.*$
ignoreregex =
EOL

systemctl restart fail2ban

# Install and configure UFW firewall
apt-get install -y ufw
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8787/tcp
ufw allow 3838/tcp
echo 'y' | ufw enable
if ! ufw status | grep -q 'Status: active'; then
    echo 'ERROR: UFW is not active after enabling' >&2
    exit 1
fi

echo 'UFW is active and configured with the following rules:'
ufw status verbose | tee -a /var/log/ufw-configuration.log

# Configure NGINX as reverse proxy
cat > /etc/nginx/sites-available/r-proxy <<EOL
server {
    listen 80;
    server_name _;

    # RStudio Server
    location /rstudio/ {
        rewrite ^/rstudio/(.*) /\$1 break;
        proxy_pass http://localhost:8787;
        proxy_redirect http://localhost:8787/ \$scheme://\$http_host/rstudio/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }

    # Shiny Server
    location /shiny/ {
        rewrite ^/shiny/(.*) /\$1 break;
        proxy_pass http://localhost:3838;
        proxy_redirect http://localhost:3838/ \$scheme://\$http_host/shiny/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }
}
EOL

# Add websocket support
cat > /etc/nginx/conf.d/websocket-upgrade.conf <<EOL
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}
EOL

# Enable the site and remove default
ln -s /etc/nginx/sites-available/r-proxy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test NGINX configuration
if ! nginx -t; then
    echo 'ERROR: NGINX configuration test failed' >&2
    exit 1
fi
systemctl restart nginx

# Verify NGINX is running
if ! systemctl is-active --quiet nginx; then
    echo 'ERROR: NGINX failed to restart' >&2
    exit 1
fi

# Verify critical services are running
for service in nginx rstudio-server shiny-server fail2ban; do
    if ! systemctl is-active --quiet $service; then
        echo "ERROR: $service is not running" >&2
        exit 1
    fi

#Or manual: sudo systemctl status nginx

# Install R packages: May take some time 110 R packages
sudo apt-get install libfribidi-dev libgit2-dev libharfbuzz-dev libtiff-dev

sudo R --vanilla << EOF || { echo 'ERROR: R package installation failed' >&2; exit 1; }
pak::pkg_install(c('DBI', 'RPostgreSQL', 'dbplyr', 'dplyr', 'tidyr', 'readr', 'purrr', 'stringr', 'forcats', 'lubridate', 'jsonlite', 'devtools', 'roxygen2', 'testthat', 'rmarkdown', 'pkgdown', 'tinytex', 'ggplot2', 'showtext', 'ggtext', 'plotly', 'shiny', 'htmltools', 'bslib', 'xml2', 'parallel', 'future', 'furrr'))
q()
EOF






#add user
# sudo adduser edgar
# sudo usermod -aG rstudio-server edgar
# Common start password for all users
START_PASSWORD="Temp@1234"

# List of users to create
users=("user1" "user2")

# Create users and set the start password
for user in "${users[@]}"; do
    # Create user without setting a password initially
    sudo adduser --disabled-password --gecos "" "$user"
    
    # Set the start password for the user using chpasswd
    echo "$user:$START_PASSWORD" | sudo chpasswd
    
    # Add user to the rstudio-server group
    sudo usermod -aG rstudio-server "$user"
    
    echo "User $user created and added to rstudio-server group with start password."
done


#Go to:
#http://<your-vm-ip>:8787
#http://<your-vm-ip>:3838

#Debugging

# List of packages to check
# packages=("gdebi-core" "libssl-dev" "libcurl4-openssl-dev" "libxml2-dev" "default-jdk" "fail2ban" "nginx" "libsodium-dev" "libpq-dev" "libopenblas-dev" "pandoc" "texlive-full" "libfreetype-dev" "libfontconfig1-dev")
# 
# # Loop over the package list and check if each is installed
# for pkg in "${packages[@]}"; do
#     if ! dpkg-query -l "$pkg" &>/dev/null; then
#         echo "$pkg is NOT installed."
#     else
#         echo "$pkg is installed."
#     fi
# done

#!/bin/bash

ssh root@ip



# Update system
apt-get update || { echo 'ERROR: apt-get update failed' >&2; exit 1; }
apt-get upgrade -y || { echo 'ERROR: apt-get upgrade failed' >&2; exit 1; }

# Install dependencies
apt-get install -y \
    gdebi-core \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    default-jdk \
    fail2ban \
    nginx \
    libsodium-dev \
    libfribidi-dev \
    libgit2-dev \
    libharfbuzz-dev \
    libtiff-dev \
    libpq-dev \
    libopenblas-dev \
    pandoc \
    texlive \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-german \
    texlive-xetex \
    libfreetype-dev \
    libfontconfig1-dev \
    ufw

# Add R repository
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu 22.04-cran40/"
apt-get update
apt-get install -y r-base r-base-dev

# Install RStudio Server
RSTUDIO_VERSION="2024.09.1-394"
wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb
sudo gdebi -n rstudio-server-${RSTUDIO_VERSION}-amd64.deb
rm rstudio-server-${RSTUDIO_VERSION}-amd64.deb

# Install Pak, Shiny and Shiny Server
R -e "install.packages('pak', repos='https://cran.rstudio.com/')"
R -e "pak::pkg_install('shiny')"

wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
gdebi -n shiny-server-*-amd64.deb
rm shiny-server-*.deb

# Setup directories and permissions
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

# Configure Shiny Server
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
access_log /var/log/shiny-server/access.log;
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

# Configure Fail2ban
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
failregex = ^.*Error in auth.: .* [ip: <HOST>].*$
            ^.*Unauthenticated request: .* [ip: <HOST>].*$
            ^.*Invalid authentication request from <HOST>.*$
            ^.*Authentication error for .* from <HOST>.*$
            ^.*Failed authentication attempt from <HOST>.*$
ignoreregex =
EOL

systemctl restart fail2ban

# Configure NGINX as reverse proxy
cat > /etc/nginx/sites-available/r-proxy <<EOL

server {
    listen 80;
    server_name _;

    # RStudio Server
    location /rstudio/ {
        rewrite ^/rstudio/(.*) /$1 break;
        proxy_pass http://localhost:8787;
        proxy_redirect http://localhost:8787/ $scheme://$http_host/rstudio/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }

    # Shiny Server
    location /shiny/ {
        rewrite ^/shiny/(.*) /$1 break;
        proxy_pass http://localhost:3838;
        proxy_redirect http://localhost:3838/ $scheme://$http_host/shiny/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }
}
EOL

# Add websocket support
# cat > /etc/nginx/conf.d/websocket-upgrade.conf <<EOL
# map $http_upgrade $connection_upgrade {
#     default         upgrade;
#     ''              close;
# }
# EOL

# Enable the site and remove default
ln -s /etc/nginx/sites-available/r-proxy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test NGINX configuration
if ! nginx -t; then
    echo 'ERROR: NGINX configuration test failed' >&2
    exit 1
fi

systemctl restart nginx

# Configure UFW firewall
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

# Install R packages
sudo R --vanilla << EOF || { echo 'ERROR: R package installation failed' >&2; exit 1; }
pak::pkg_install(c('DBI', 'RPostgreSQL', 'dbplyr', 'RSQLite', 'dplyr', 'tidyr', 'readr', 'purrr', 'stringr', 'forcats', 'lubridate', 'jsonlite', 'yaml', 'readxl', 'writexl', 'devtools', 'roxygen2', 'testthat', 'pak', 'remotes', 'usethis', 'rmarkdown', 'pkgdown', 'tinytex', 'knitr', 'quarto', 'ggplot2', 'showtext', 'ggtext', 'plotly', 'viridis', 'scales', 'patchwork', 'gganimate', 'shiny', 'htmltools', 'bslib', 'xml2', 'httr2', 'sass', 'websocket', 'httpuv', 'parallel', 'future', 'furrr', 'data.table', 'dtplyr', 'profvis'))
q()
EOF

# Create users
START_PASSWORD="Temp@1234"

# List of users to create
users=("u" "er1" " u" "er2")

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

# Verify critical services are running
for service in nginx rstudio-server shiny-server fail2ban; do
    if ! systemctl is-active --quiet $service; then
        echo "ERROR: $service is not running" >&2
        exit 1
    fi
done

echo 'Installation completed successfully!'
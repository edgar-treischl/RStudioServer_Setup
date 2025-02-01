#!/bin/bash

#ssh root@ip



# Update
apt-get update
apt-get upgrade -y

################################################################################
# 01: Install Docker
################################################################################

# Add Docker's Official GPG Key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc

# Add Docker Repository
echo "Adding Docker repository..."
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update Package Index Again to include Docker packages
echo "Updating package index again..."
sudo apt update -y

# Install Docker CE
echo "Installing Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Start and Enable Docker
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the Docker group
#echo "Adding current user to Docker group..."
#sudo usermod -aG docker $(whoami)

# Verify Docker Installation
echo "Verifying Docker installation..."
docker --version
sudo systemctl status docker

# Test Installation
echo "Running Docker hello-world test..."
sudo docker run hello-world

################################################################################
# 02 Install dependencies for R Server
################################################################################
echo "Installing dependencies..."
sudo apt-get install -y \
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
ufw \
libv8-dev

# Cleanup
echo "Cleaning up..."
sudo apt-get clean

# Add R repository
echo "Adding R repository..."
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee /usr/share/keyrings/cran-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" | sudo tee /etc/apt/sources.list.d/cran.list > /dev/null
sudo apt-get update
sudo apt-get install -y r-base r-base-dev

# Install RStudio Server
RSTUDIO_VERSION="2024.12.0-467"
echo "Installing RStudio Server version ${RSTUDIO_VERSION}..."
wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb
sudo gdebi -n rstudio-server-${RSTUDIO_VERSION}-amd64.deb
rm rstudio-server-${RSTUDIO_VERSION}-amd64.deb


# Install Pak, Shiny
echo "Installing Pak and Shiny..."
sudo R --vanilla <<EOF
install.packages('pak', repos='https://cran.rstudio.com/')
pak::pkg_install('shiny')
EOF

################################################################################
# 03 Install Shiny Server and Config
################################################################################

echo "Installing Shiny Server..."
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
sudo gdebi -n shiny-server-1.5.22.1017-amd64.deb
rm shiny-server-1.5.22.1017-amd64.deb

# Setup directories and permissions
echo "Setting up directories and permissions for Shiny Server..."
sudo mkdir -p /srv/shiny-server
sudo chown -R shiny:shiny /srv/shiny-server
sudo chmod -R 755 /srv/shiny-server

# Configure logging directories and permissions
sudo mkdir -p /var/log/rstudio
sudo mkdir -p /var/log/shiny-server
sudo touch /var/log/rstudio/rserver-http-access.log
sudo touch /var/log/shiny-server/shiny-server.log
sudo chown -R rstudio-server:rstudio-server /var/log/rstudio
sudo chown -R shiny:shiny /var/log/shiny-server

# Configure Shiny Server logging
echo "Configuring Shiny Server logging..."
sudo tee /etc/shiny-server/shiny-server.conf > /dev/null <<EOL
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
echo "Configuring logrotate for Shiny Server..."
sudo tee /etc/logrotate.d/shiny-server > /dev/null <<EOL
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
echo "Testing Shiny Server configuration..."
if ! sudo systemctl restart shiny-server; then
  echo 'ERROR: Shiny Server failed to restart with new configuration'
  exit 1
fi

if [ ! -f /var/log/shiny-server/access.log ]; then
  echo 'WARNING: Shiny Server access log file not created' >&2
fi

# Configure Fail2ban for RStudio and Shiny Server
echo "Configuring Fail2ban for RStudio and Shiny Server..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[DEFAULT]
allowipv6 = auto

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

sudo tee /etc/fail2ban/filter.d/rstudio-server.conf > /dev/null <<EOL
[Definition]
failregex = ^.*Failed login attempt for user .* from IP <HOST>.*$
ignoreregex =
EOL

sudo tee /etc/fail2ban/filter.d/shiny-server.conf > /dev/null <<EOL
[Definition]
# Detect failed authentication attempts
failregex = ^.*Error in auth.: .* \[ip: <HOST>\].*$
            ^.*Unauthenticated request: .* \[ip: <HOST>\].*$
            ^.*Invalid authentication request from <HOST>.*$
            ^.*Authentication error for .* from <HOST>.*$
            ^.*Failed authentication attempt from <HOST>.*$
ignoreregex =
EOL

sudo systemctl restart fail2ban

# Install and configure UFW firewall
echo "Installing and configuring UFW firewall..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8787/tcp
sudo ufw allow 3838/tcp
echo 'y' | sudo ufw enable
if ! sudo ufw status | grep -q 'Status: active'; then
  echo 'ERROR: UFW is not active after enabling' >&2
  exit 1
fi

echo 'UFW is active and configured with the following rules:'
sudo ufw status verbose | tee -a /var/log/ufw-configuration.log

# Configure NGINX as reverse proxy
echo "Configuring NGINX as reverse proxy..."
sudo tee /etc/nginx/sites-available/r-proxy > /dev/null <<EOL
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
sudo tee /etc/nginx/conf.d/websocket-upgrade.conf > /dev/null <<EOL
map \$http_upgrade \$connection_upgrade {
  default upgrade;
  ''      close;
}
EOL

# Enable the site and remove default
sudo ln -s /etc/nginx/sites-available/r-proxy /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test NGINX configuration
echo "Testing NGINX configuration..."
if ! sudo nginx -t; then
  echo 'ERROR: NGINX configuration test failed'
  exit 1
fi

# Restart NGINX
echo "Restarting NGINX..."
sudo systemctl restart nginx

# Verify NGINX is running
if ! sudo systemctl is-active --quiet nginx; then
  echo 'ERROR: NGINX failed to restart'
  exit 1
fi

# Verify critical services are running
echo "Verifying critical services are running..."
for service in nginx rstudio-server shiny-server fail2ban; do
  if ! sudo systemctl is-active --quiet $service; then
    echo "ERROR: $service is not running"
  fi
done  

################################################################################
# 04: Install R environment => add renv here
################################################################################

# Install R packages: This may take some time: 110 R packages
echo "Installing R packages..."
sudo R --vanilla <<EOF || { echo 'ERROR: R package installation failed' >&2; exit 1; }
pak::pkg_install(c('rmarkdown', 'renv', 'DBI', 'RPostgreSQL', 'dbplyr', 'dplyr', 'tidyr', 'readr', 'purrr', 'stringr', 'forcats', 'lubridate', 'jsonlite', 'devtools', 'roxygen2', 'testthat', 'rmarkdown', 'pkgdown', 'tinytex', 'ggplot2', 'showtext', 'ggtext', 'plotly', 'shiny', 'htmltools', 'bslib', 'xml2', 'parallel', 'future', 'furrr'))
q()
EOF




################################################################################
# 05: Add users
################################################################################

# sudo adduser edgar
# sudo usermod -aG rstudio-server edgar

# We need an account for each team member
# Common start password for all users
START_PASSWORD="Temp@1234"

# List of users to create
users=("edgar" "stefan" "victoria")

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


# Go to:
# R Studio Server
#http://<your-vm-ip>:8787
#http://165.227.170.140:8787



# Shiny Server
#http://<your-vm-ip>:3838
#http://165.227.170.140:3838

################################################################################
# Further Ado: Installation END
################################################################################


# Further software:
# Posit's recommended packages:       #(https://docs.posit.co/connect/admin/r/dependencies/index.html)
# libcairo2-dev \                       # Graphics library for rendering (important for R plots)
# make \                                # Tool for building and compiling software (useful for building R packages)
# libmysqlclient-dev \                  # MySQL development libraries (for working with MySQL databases)
# unixodbc-dev \                        # ODBC libraries (for database connectivity)
# libnode-dev \                         # Node.js development libraries (may be required for web or JavaScript integration)
# libx11-dev \                          # X11 libraries (used for GUI development on X-based systems)
# git \                                 # Git version control system
# zlib1g-dev \                          # Compression library (important for many software builds)
# libglpk-dev \                         # Linear programming optimization library
# libjpeg-dev \                         # JPEG image library
# libmagick++-dev \                     # ImageMagick development libraries (useful for image manipulation)
# gsfonts \                             # Fonts for Ghostscript (used for PDF generation)
# cmake \                               # Build system generator (used to compile complex software)
# libpng-dev \                          # PNG image library
# python3 \                             # Python 3 (required for some R packages that interface with Python)
# libglu1-mesa-dev \                    # OpenGL development libraries (for 3D graphics)
# libgl1-mesa-dev \                     # OpenGL libraries (for rendering graphics)
# libgdal-dev \                         # Geospatial Data Abstraction Library (for working with spatial data)
# gdal-bin \                            # GDAL utilities (used for geospatial data processing)
# libgeos-dev \                         # Geometry Engine library (for spatial data operations)
# libproj-dev \                         # Projection library (used with geospatial data)
# libsqlite3-dev \                      # SQLite database libraries
# libicu-dev \                          # International Components for Unicode (for string handling in different languages)
# tcl \                                 # Tcl scripting language (used with Tk for GUI)
# tk \                                  # Tk GUI toolkit (used with Tcl)
# tk-dev \                              # Development files for Tk (needed for building Tk applications)
# tk-table \                            # Tk table widget (used for interactive tables in GUIs)
# libudunits2-dev \                     # Unit conversion library (used for handling units of measurement in R)



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

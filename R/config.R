# Version options
ubuntu_versions <- c(
  "Ubuntu 22.04 LTS (Jammy Jellyfish)" = "22.04",
  "Ubuntu 20.04 LTS (Focal Fossa)" = "20.04",
  "Ubuntu 18.04 LTS (Bionic Beaver)" = "18.04"
)

r_versions <- c(
  "Latest (4.3.x)" = "latest",
  "4.2.x" = "4.2",
  "4.1.x" = "4.1"
)

# RStudio Server version
rstudio_version <- "2024.09.1-394"

# Dependencies
required_dependencies <- c(
  "gdebi-core",
  "libssl-dev",
  "libcurl4-openssl-dev",
  "libxml2-dev",
  "default-jdk",
  "fail2ban",
  "nginx",
  "libsodium-dev",
  "libfribidi-dev",
  "libgit2-dev", 
  "libharfbuzz-dev",
  "libtiff-dev",
  "libpq-dev",
  "libopenblas-dev",
  "pandoc",
  "texlive-full",
  "libfreetype-dev",
  "libfontconfig1-dev",
  "ufw"
)

# Package configurations
r_package_groups <- list(
  "Database" = c(
    "DBI", 
    "RPostgreSQL", 
    "dbplyr", 
    "RSQLite"
  ),
  "Core Data" = c(
    "dplyr", 
    "tidyr", 
    "readr", 
    "purrr",
    "stringr", 
    "forcats", 
    "lubridate",
    "jsonlite",
    "yaml",
    "readxl",
    "writexl"
  ),
  "Development" = c(
    "devtools", 
    "roxygen2", 
    "testthat", 
    "pak",
    "remotes",
    "usethis"
  ),
  "Documentation" = c(
    "rmarkdown", 
    "pkgdown", 
    "tinytex",
    "knitr",
    "quarto"
  ),
  "Graphics" = c(
    "ggplot2", 
    "showtext", 
    "ggtext", 
    "plotly",
    "viridis",
    "scales",
    "patchwork",
    "gganimate"
  ),
  "Web" = c(
    "shiny", 
    "htmltools", 
    "bslib", 
    "xml2",
    "httr2",
    "sass",
    "websocket",
    "httpuv"
  ),
  "Performance" = c(
    "parallel", 
    "future", 
    "furrr",
    "data.table",
    "dtplyr",
    "profvis"
  )
)

# System users configuration
default_users <- c("user1", "user2")
default_password <- "Temp@1234"

# Nginx configuration templates
nginx_proxy_config <- '
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
}'

nginx_websocket_config <- 'map $http_upgrade $connection_upgrade {
    default upgrade;
    ""      close;
}'

# Shiny Server configuration
shiny_server_config <- '
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
log_dir /var/log/shiny-server;'

# Fail2ban configuration templates
fail2ban_jail_config <- '
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
bantime = 3600'

fail2ban_rstudio_filter <- '
[Definition]
failregex = ^.*Failed login attempt for user .* from IP <HOST>.*$
ignoreregex ='

fail2ban_shiny_filter <- '
[Definition]
# Detect failed authentication attempts
failregex = ^.*Error in auth.: .* [ip: <HOST>].*$
            ^.*Unauthenticated request: .* [ip: <HOST>].*$
            ^.*Invalid authentication request from <HOST>.*$
            ^.*Authentication error for .* from <HOST>.*$
            ^.*Failed authentication attempt from <HOST>.*$
ignoreregex ='

# Logrotate configuration
logrotate_config <- '
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
}'
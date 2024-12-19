generate_script <- function(ubuntu_version, r_version, selected_packages) {
  script_parts <- list()
  
  # Add shebang and header
  script_parts$header <- c(
    "#!/bin/bash",
    "",
    "# Exit on error",
    "set -e",
    "",
    "# Update system",
    "apt-get update || { echo 'ERROR: apt-get update failed' >&2; exit 1; }",
    "apt-get upgrade -y || { echo 'ERROR: apt-get upgrade failed' >&2; exit 1; }"
  )
  
  # Install dependencies
  script_parts$dependencies <- c(
    "",
    "# Install dependencies",
    paste("apt-get install -y", paste(required_dependencies, collapse = " "))
  )
  
  # R installation
  script_parts$r_install <- c(
    "",
    "# Add R repository",
    "wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc",
    paste0("add-apt-repository \"deb https://cloud.r-project.org/bin/linux/ubuntu ", ubuntu_version, "-cran40/\""),
    "apt-get update",
    if(r_version == "latest") {
      "apt-get install -y r-base r-base-dev"
    } else {
      paste0("apt-get install -y r-base=", r_version, "* r-base-dev=", r_version, "*")
    }
  )
  
  # RStudio Server installation
  script_parts$rstudio <- c(
    "",
    "# Install RStudio Server",
    paste0("RSTUDIO_VERSION=\"", rstudio_version, "\""),
    "wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb",
    "sudo gdebi -n rstudio-server-${RSTUDIO_VERSION}-amd64.deb",
    "rm rstudio-server-${RSTUDIO_VERSION}-amd64.deb"
  )
  
  # Shiny and Shiny Server installation
  script_parts$shiny <- c(
    "",
    "# Install Pak, Shiny and Shiny Server",
    "R -e \"install.packages('pak', repos='https://cran.rstudio.com/')\"",
    "R -e \"pak::pkg_install('shiny', repos='https://cran.rstudio.com/')\"",
    "",
    "wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb",
    "gdebi -n shiny-server-*-amd64.deb",
    "rm shiny-server-*.deb"
  )
  
  # Directory and permissions setup
  script_parts$directories <- c(
    "",
    "# Setup directories and permissions",
    "mkdir -p /srv/shiny-server",
    "chown -R shiny:shiny /srv/shiny-server",
    "chmod -R 755 /srv/shiny-server",
    "",
    "# Configure logging directories and permissions",
    "mkdir -p /var/log/rstudio",
    "mkdir -p /var/log/shiny-server",
    "touch /var/log/rstudio/rserver-http-access.log",
    "touch /var/log/shiny-server/shiny-server.log",
    "chown -R rstudio-server:rstudio-server /var/log/rstudio",
    "chown -R shiny:shiny /var/log/shiny-server"
  )
  
  # Shiny Server configuration
  script_parts$shiny_config <- c(
    "",
    "# Configure Shiny Server",
    "cat > /etc/shiny-server/shiny-server.conf <<EOL",
    shiny_server_config,
    "EOL"
  )
  
  # Logrotate configuration
  script_parts$logrotate <- c(
    "",
    "# Configure logrotate for Shiny Server",
    "cat > /etc/logrotate.d/shiny-server <<EOL",
    logrotate_config,
    "EOL"
  )
  
  # Configure fail2ban
  script_parts$fail2ban <- c(
    "",
    "# Configure Fail2ban",
    "cat > /etc/fail2ban/jail.local <<EOL",
    fail2ban_jail_config,
    "EOL",
    "",
    "cat > /etc/fail2ban/filter.d/rstudio-server.conf <<EOL",
    fail2ban_rstudio_filter,
    "EOL",
    "",
    "cat > /etc/fail2ban/filter.d/shiny-server.conf <<EOL",
    fail2ban_shiny_filter,
    "EOL",
    "",
    "systemctl restart fail2ban"
  )
  
  # Configure NGINX
  script_parts$nginx <- c(
    "",
    "# Configure NGINX as reverse proxy",
    "cat > /etc/nginx/sites-available/r-proxy <<EOL",
    nginx_proxy_config,
    "EOL",
    "",
    "# Add websocket support",
    "cat > /etc/nginx/conf.d/websocket-upgrade.conf <<EOL",
    nginx_websocket_config,
    "EOL",
    "",
    "# Enable the site and remove default",
    "ln -s /etc/nginx/sites-available/r-proxy /etc/nginx/sites-enabled/",
    "rm -f /etc/nginx/sites-enabled/default",
    "",
    "# Test NGINX configuration",
    "if ! nginx -t; then",
    "    echo 'ERROR: NGINX configuration test failed' >&2",
    "    exit 1",
    "fi",
    "systemctl restart nginx"
  )
  
  # Configure firewall
  script_parts$firewall <- c(
    "",
    "# Configure UFW firewall",
    "ufw allow ssh",
    "ufw allow http",
    "ufw allow https",
    "ufw allow 8787/tcp",
    "ufw allow 3838/tcp",
    "echo 'y' | ufw enable",
    "if ! ufw status | grep -q 'Status: active'; then",
    "    echo 'ERROR: UFW is not active after enabling' >&2",
    "    exit 1",
    "fi",
    "",
    "echo 'UFW is active and configured with the following rules:'",
    "ufw status verbose | tee -a /var/log/ufw-configuration.log"
  )
  
  # Install R packages
  if (length(selected_packages) > 0) {
    script_parts$packages <- c(
      "",
      "# Install R packages",
      "sudo R --vanilla << EOF || { echo 'ERROR: R package installation failed' >&2; exit 1; }",
      paste0("pak::pkg_install(c('", paste(selected_packages, collapse = "', '"), "'))"),
      "q()",
      "EOF"
    )
  }
  
  # Create users
  script_parts$users <- c(
    "",
    "# Create users",
    paste0("START_PASSWORD=\"", default_password, "\""),
    "",
    "# List of users to create",
    paste0("users=(", paste(sprintf("\"%s\"", default_users), collapse = " "), ")"),
    "",
    "# Create users and set the start password",
    "for user in \"${users[@]}\"; do",
    "    # Create user without setting a password initially",
    "    sudo adduser --disabled-password --gecos \"\" \"$user\"",
    "    ",
    "    # Set the start password for the user using chpasswd",
    "    echo \"$user:$START_PASSWORD\" | sudo chpasswd",
    "    ",
    "    # Add user to the rstudio-server group",
    "    sudo usermod -aG rstudio-server \"$user\"",
    "    ",
    "    echo \"User $user created and added to rstudio-server group with start password.\"",
    "done"
  )
  
  # Service verification
  script_parts$verify <- c(
    "",
    "# Verify critical services are running",
    "for service in nginx rstudio-server shiny-server fail2ban; do",
    "    if ! systemctl is-active --quiet $service; then",
    "        echo \"ERROR: $service is not running\" >&2",
    "        exit 1",
    "    fi",
    "done",
    "",
    "echo 'Installation completed successfully!'"
  )
  
  # Combine all parts
  script <- unlist(script_parts)
  paste(script, collapse = "\n")
}
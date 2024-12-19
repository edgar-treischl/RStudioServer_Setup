library(shiny)
library(bslib)



# List of available options
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

# Required dependencies that will always be installed
required_dependencies <- c(
  "gdebi-core",              # Required for installing .deb packages
  "libssl-dev",              # Required for R packages with SSL/TLS
  "libcurl4-openssl-dev",    # Required for R packages that use curl
  "libxml2-dev",             # Required for package installation
  "default-jdk",             # Required for Java-based R packages and operations
  "fail2ban",                # Required for security protection
  "nginx",                   # Required for reverse proxy
  "libsodium-dev"           # Required for encryption and security
)

# Recommended dependencies with descriptions
recommended_dependencies <- list(
  "libpq-dev" = "Required for PostgreSQL database connections",
  "libopenblas-dev" = "Optimized BLAS library for better performance"
)

# Map R packages to their required system dependencies
package_dependencies <- list(
  "rmarkdown" = c("pandoc-citeproc"),
  "tinytex" = c("texlive-full"),
  "showtext" = c("libfreetype6-dev", "libfontconfig1-dev"),
  "xml2" = character(0) 
)

# R package groups
r_package_groups <- list(
  "Database" = c("DBI", "RPostgreSQL", "dbplyr"),
  "Core Data" = c(
    "dplyr", "tidyr", "readr", "purrr",
    "stringr", "forcats", "lubridate",
    "jsonlite"
  ),
  "Development" = c("devtools", "roxygen2", "testthat"),
  "Documentation" = c("rmarkdown", "pkgdown", "tinytex"),
  "Graphics" = c("ggplot2", "showtext", "ggtext", "plotly"),
  "Web" = c("shiny", "htmltools", "bslib", "xml2"),
  "Performance" = c("parallel", "future", "furrr")
)

ui <- page_sidebar(
  title = "Ubuntu R Setup Generator",
  sidebar = sidebar(
    actionButton("generate", "Generate Script", class = "btn-primary"),
    selectInput("ubuntu_version", "Ubuntu Version", ubuntu_versions),
    selectInput("r_version", "R Version", r_versions),
    numericInput("shiny_version", "Shiny Server Version", 1.5, min = 1.0, max = 2.0, step = 0.1),
    
    tags$div(
      tags$p("Required Dependencies (always included):", class = "fw-bold"),
      tags$ul(
        lapply(required_dependencies, function(dep) tags$li(dep))
      )
    ),
    
    tags$div(
      tags$p("Recommended Dependencies:", class = "fw-bold"),
      checkboxGroupInput("recommended_deps", "Recommended System Dependencies",
                         choices = names(recommended_dependencies),
                         selected = names(recommended_dependencies))
    ),
    
    tags$hr(),
    
    # Selection buttons
    div(class = "d-flex justify-content-between mb-3",
        actionButton("select_all", "Select All", class = "btn-sm btn-secondary"),
        actionButton("deselect_all", "Deselect All", class = "btn-sm btn-secondary")
    ),
    
    # R packages selection
    tags$p("R Packages to Install:", class = "fw-bold"),
    lapply(names(r_package_groups), function(group) {
      checkboxGroupInput(
        paste0("pkg_", tolower(gsub(" ", "_", group))),
        group,
        choices = r_package_groups[[group]],
        selected = r_package_groups[[group]]  # Default all selected
      )
    })
  ),
  card(
    card_header(
      div(class = "d-flex justify-content-between align-items-center",
          "Generated Bash Script",
          actionButton("copy", "Copy", class = "btn-sm btn-secondary")
      )
    ),
    pre(
      id = "bash_output",
      verbatimTextOutput("bash_script")
    )
  )
)

server <- function(input, output, session) {
  # Helper function to get all package choices
  get_all_packages <- reactive({
    unlist(r_package_groups)
  })
  
  # Select all button
  observeEvent(input$select_all, {
    all_packages <- get_all_packages()
    for(group in names(r_package_groups)) {
      updateCheckboxGroupInput(
        session,
        paste0("pkg_", tolower(gsub(" ", "_", group))),
        selected = r_package_groups[[group]]
      )
    }
  })
  
  # Deselect all button
  observeEvent(input$deselect_all, {
    for(group in names(r_package_groups)) {
      updateCheckboxGroupInput(
        session,
        paste0("pkg_", tolower(gsub(" ", "_", group))),
        selected = character(0)
      )
    }
  })
  
  get_selected_packages <- reactive({
    selected <- c()
    for(group in names(r_package_groups)) {
      input_name <- paste0("pkg_", tolower(gsub(" ", "_", group)))
      selected <- c(selected, input[[input_name]])
    }
    unique(selected)
  })
  
  get_required_system_deps <- reactive({
    selected_packages <- get_selected_packages()
    system_deps <- c()
    
    for(pkg in selected_packages) {
      if(pkg %in% names(package_dependencies)) {
        system_deps <- c(system_deps, package_dependencies[[pkg]])
      }
    }
    
    unique(system_deps)
  })
  
  script <- eventReactive(input$generate, {
    # Combine all dependencies
    all_dependencies <- c(
      required_dependencies,
      input$recommended_deps,
      get_required_system_deps()
    )
    
    # Base script with system updates
    script_parts <- c(
      "#!/bin/bash",
      "\n# Update system",
      "apt-get update || { echo 'ERROR: apt-get update failed' >&2; exit 1; }",
      "apt-get upgrade -y || { echo 'ERROR: apt-get upgrade failed' >&2; exit 1; }",
      
      "\n# Install dependencies",
      paste("apt-get install -y", paste(all_dependencies, collapse = " "))
    )
    
    # Add R installation
    if (input$r_version == "latest") {
      script_parts <- c(script_parts,
                        "\n# Add R repository",
                        "wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc",
                        paste0("add-apt-repository \"deb https://cloud.r-project.org/bin/linux/ubuntu ", input$ubuntu_version, "-cran40/\""),
                        "apt-get update",
                        "apt-get install -y r-base r-base-dev"
      )
    } else {
      script_parts <- c(script_parts,
                        "\n# Install specific R version",
                        paste0("apt-get install -y r-base=", input$r_version, "* r-base-dev=", input$r_version, "*")
      )
    }
    
    # Add RStudio installation
    script_parts <- c(script_parts,
                      "\n# Install RStudio Server",
                      if (input$ubuntu_version == "22.04") {
                        c(
                          "RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://download2.rstudio.org/server/jammy/amd64/VERSION)",
                          "wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_LATEST}-amd64.deb"
                        )
                      } else if (input$ubuntu_version == "20.04") {
                        c(
                          "RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://download2.rstudio.org/server/focal/amd64/VERSION)",
                          "wget -q https://download2.rstudio.org/server/focal/amd64/rstudio-server-${RSTUDIO_LATEST}-amd64.deb"
                        )
                      } else {
                        c(
                          "RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://download2.rstudio.org/server/bionic/amd64/VERSION)",
                          "wget -q https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_LATEST}-amd64.deb"
                        )
                      },
                      "gdebi -n rstudio-server-${RSTUDIO_LATEST}-amd64.deb",
                      "rm rstudio-server-*-amd64.deb"
    )
    
    # Add Shiny Server installation
    script_parts <- c(script_parts,
                      "\n# Install Shiny and Shiny Server",
                      "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\"",
                      if (input$ubuntu_version == "22.04") {
                        paste0("wget https://download3.rstudio.org/ubuntu-22.04/x86_64/shiny-server-", input$shiny_version, "-amd64.deb")
                      } else if (input$ubuntu_version == "20.04") {
                        paste0("wget https://download3.rstudio.org/ubuntu-20.04/x86_64/shiny-server-", input$shiny_version, "-amd64.deb")
                      } else {
                        paste0("wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-", input$shiny_version, "-amd64.deb")
                      },
                      "gdebi -n shiny-server-*-amd64.deb",
                      "rm shiny-server-*.deb",
                      
                      # Add directory setup
                      "\n# Ensure Shiny app directory exists with correct permissions",
                      "mkdir -p /srv/shiny-server",
                      "chown -R shiny:shiny /srv/shiny-server",
                      "chmod -R 755 /srv/shiny-server"
    )
    
    script_parts <- c(script_parts,
                      "\n# Configure logging directories and permissions",
                      "mkdir -p /var/log/rstudio",
                      "mkdir -p /var/log/shiny-server",
                      "touch /var/log/rstudio/rserver-http-access.log",
                      "touch /var/log/shiny-server/shiny-server.log",
                      "chown -R rstudio-server:rstudio-server /var/log/rstudio",
                      "chown -R shiny:shiny /var/log/shiny-server",
                      
                      "\n# Configure RStudio Server logging",
                      "cat > /etc/rstudio/logging.conf <<EOL",
                      "[@access]",
                      "log-level=info",
                      "logger-type=file",
                      "path=/var/log/rstudio/rserver-http-access.log",
                      "EOL",
                      
                      "\n# Configure Shiny Server logging",
                      "cat > /etc/shiny-server/shiny-server.conf <<EOL",
                      "# Define the user we should use when spawning R Shiny processes",
                      "run_as shiny;",
                      "",
                      "# Define a top-level server which will listen on a port",
                      "server {",
                      "  listen 3838;",
                      "",
                      "  # Define the location available at the base URL",
                      "  location / {",
                      "    site_dir /srv/shiny-server;",
                      "    log_dir /var/log/shiny-server;",
                      "    directory_index on;",
                      "  }",
                      "}",
                      "",
                      "# Configure logging",
                      "preserve_logs true;",
                      "access_log /var/log/shiny-server/access.log;",
                      "server_log /var/log/shiny-server/server.log;",
                      "EOL",
                      
                      "\n# Configure logrotate for Shiny Server",
                      "cat > /etc/logrotate.d/shiny-server <<EOL",
                      "/var/log/shiny-server/*.log {",
                      "    rotate 7",
                      "    daily",
                      "    missingok",
                      "    notifempty",
                      "    compress",
                      "    delaycompress",
                      "    postrotate",
                      "        systemctl reload shiny-server > /dev/null 2>/dev/null || true",
                      "    endscript",
                      "    create 0644 shiny shiny",
                      "}",
                      "EOL",
                      
                      "\n# Test Shiny Server configuration",
                      "if ! systemctl restart shiny-server; then",
                      "    echo 'ERROR: Shiny Server failed to restart with new configuration' >&2",
                      "    exit 1",
                      "fi",
                      
                      "\n# Verify log files are being written",
                      "sleep 2",
                      "if [ ! -f /var/log/shiny-server/server.log ]; then",
                      "    echo 'WARNING: Shiny Server log file not created' >&2",
                      "fi"
    )
    
    # Configure Fail2ban
    script_parts <- c(script_parts,
                      "\n# Configure Fail2ban for RStudio and Shiny Server",
                      "cat > /etc/fail2ban/jail.local <<EOL",
                      "[rstudio-server]",
                      "enabled = true",
                      "port = 8787",
                      "filter = rstudio-server",
                      "logpath = /var/log/rstudio/rserver-http-access.log",
                      "maxretry = 3",
                      "bantime = 3600",
                      "",
                      "[shiny-server]",
                      "enabled = true",
                      "port = 3838",
                      "filter = shiny-server",
                      "logpath = /var/log/shiny-server.log",
                      "maxretry = 3",
                      "bantime = 3600",
                      "EOL",
                      "",
                      "cat > /etc/fail2ban/filter.d/rstudio-server.conf <<EOL",
                      "[Definition]",
                      "failregex = ^.*Failed login attempt for user .* from IP <HOST>.*$",
                      "ignoreregex =",
                      "EOL",
                      "",
                      "cat > /etc/fail2ban/filter.d/shiny-server.conf <<EOL",
                      "[Definition]",
                      "# Detect failed authentication attempts",
                      "failregex = ^.*Error in auth.: .* \\[ip: <HOST>\\].*$",
                      "            ^.*Unauthenticated request: .* \\[ip: <HOST>\\].*$",
                      "            ^.*Invalid authentication request from <HOST>.*$",
                      "            ^.*Authentication error for .* from <HOST>.*$",
                      "            ^.*Failed authentication attempt from <HOST>.*$",
                      "ignoreregex =",
                      "EOL",
                      "",
                      "systemctl restart fail2ban"
    )
    
    # Configure NGINX
    script_parts <- c(script_parts,
                      "\n# Install and configure UFW firewall",
                      "apt-get install -y ufw",
                      "ufw allow ssh",
                      "ufw allow http",
                      "ufw allow https",
                      "ufw allow 8787/tcp",
                      "ufw allow 3838/tcp",
                      "echo 'y' | ufw enable",
                      
                      # Add status check and logging
                      "if ! ufw status | grep -q 'Status: active'; then",
                      "    echo 'ERROR: UFW is not active after enabling' >&2",
                      "    exit 1",
                      "fi",
                      "echo 'UFW is active and configured with the following rules:'",
                      "ufw status verbose | tee -a /var/log/ufw-configuration.log"
    )
    
    script_parts <- c(script_parts,
                      "\n# Configure NGINX as reverse proxy",
                      "cat > /etc/nginx/sites-available/r-proxy <<EOL",
                      "server {",
                      "    listen 80;",
                      "    server_name _;",
                      "",
                      "    # RStudio Server",
                      "    location /rstudio/ {",
                      "        rewrite ^/rstudio/(.*) /\\$1 break;",
                      "        proxy_pass http://localhost:8787;",
                      "        proxy_redirect http://localhost:8787/ \\$scheme://\\$http_host/rstudio/;",
                      "        proxy_http_version 1.1;",
                      "        proxy_set_header Upgrade \\$http_upgrade;",
                      "        proxy_set_header Connection \\$connection_upgrade;",
                      "        proxy_read_timeout 20d;",
                      "        proxy_buffering off;",
                      "    }",
                      "",
                      "    # Shiny Server",
                      "    location /shiny/ {",
                      "        rewrite ^/shiny/(.*) /\\$1 break;",
                      "        proxy_pass http://localhost:3838;",
                      "        proxy_redirect http://localhost:3838/ \\$scheme://\\$http_host/shiny/;",
                      "        proxy_http_version 1.1;",
                      "        proxy_set_header Upgrade \\$http_upgrade;",
                      "        proxy_set_header Connection \\$connection_upgrade;",
                      "        proxy_read_timeout 20d;",
                      "        proxy_buffering off;",
                      "    }",
                      "}",
                      "EOL",
                      "",
                      "# Add websocket support",
                      "cat > /etc/nginx/conf.d/websocket-upgrade.conf <<EOL",
                      "map \\$http_upgrade \\$connection_upgrade {",
                      "    default upgrade;",
                      "    ''      close;",
                      "}",
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
                      "systemctl restart nginx",
                      "",
                      "# Verify NGINX is running",
                      "if ! systemctl is-active --quiet nginx; then",
                      "    echo 'ERROR: NGINX failed to restart' >&2",
                      "    exit 1",
                      "fi"
    )
    
    # Add this after the NGINX restart section
    script_parts <- c(script_parts,
                      "\n# Verify critical services are running",
                      "for service in nginx rstudio-server shiny-server fail2ban; do",
                      "    if ! systemctl is-active --quiet $service; then",
                      "        echo \"ERROR: $service is not running\" >&2",
                      "        exit 1",
                      "    fi",
                      "done"
    )
    
    # R packages installation using pak
    selected_packages <- get_selected_packages()
    if (length(selected_packages) > 0) {
      script_parts <- c(script_parts,
                        "\n# Install pak and R packages",
                        "R --vanilla << EOF || { echo 'ERROR: R package installation failed' >&2; exit 1; }",
                        "install.packages('pak', repos = 'https://r-lib.github.io/p/pak/dev/')",
                        paste0("pak::pkg_install(c('", paste(selected_packages, collapse = "', '"), "'))"),
                        "q()",
                        "EOF"
      )
    }
    
    # Combine all parts
    paste(script_parts, collapse = "\n")
  })
  
  output$bash_script <- renderText({
    script()
  })
  
  # Copy button functionality
  observeEvent(input$copy, {
    clipr::write_clip(script())
    showNotification("Script copied to clipboard!", type = "message")
  })
}

shinyApp(ui, server)
library(shiny)
library(bslib)

# Source data and configuration files
source(here::here("R", "config.R"))
source(here::here("R", "generate_script.R"))


ui <- page_sidebar(
  theme = bs_theme(version = 5),
  title = "Ubuntu R Server Setup Generator",
  sidebar = sidebar(
    width = "20%",
    # System Settings card
    card(
      actionButton("generate", "Generate Script", 
                   class = "btn-lg btn-primary w-100 mt-3"),
      card_header("System Settings"),
      selectInput("ubuntu_version", "Ubuntu Version", ubuntu_versions),
      selectInput("r_version", "R Version", r_versions)
    ),
    
    # Package Selection card
    card(
      card_header(
        "R Packages",
        div(class = "d-flex gap-2",
            actionButton("select_all", "Select All", class = "btn-sm btn-secondary"),
            actionButton("deselect_all", "Deselect All", class = "btn-sm btn-secondary")
        )
      ),
      accordion(
        lapply(names(r_package_groups), function(group) {
          accordion_panel(
            group,
            checkboxGroupInput(
              paste0("pkg_", tolower(gsub(" ", "_", group))),
              NULL,
              choices = r_package_groups[[group]],
              selected = r_package_groups[[group]]
            )
          )
        })
      )
    ),
    
    # User Settings card
    card(
      card_header("User Settings"),
      textInput("users", "Users (comma-separated)", 
                value = paste(default_users, collapse = ", ")),
      passwordInput("password", "Default Password", 
                    value = default_password)
    )
  ),
  
  # Main panel
  card(
    width = "80%",
    card_header(
      div(class = "d-flex justify-content-between align-items-center",
          span(class = "h5 m-0", "Generated Installation Script"),
          div(class = "btn-group",
              downloadButton("download", "Download", class = "btn-sm btn-secondary"),
              actionButton("copy", "Copy", class = "btn-sm btn-secondary")
          )
      )
    ),
    card_body(
      style = "max-height: calc(100vh - 200px); overflow-y: auto;",
      pre(
        id = "script_output",
        class = "p-3 bg-light",
        verbatimTextOutput("bash_script")
      )
    )
  )
)

server <- function(input, output, session) {
  # Package selection logic
  selected_packages <- reactive({
    packages <- c()
    for(group in names(r_package_groups)) {
      input_name <- paste0("pkg_", tolower(gsub(" ", "_", group)))
      packages <- c(packages, input[[input_name]])
    }
    unique(packages)
  })
  
  # Select/Deselect all logic
  observeEvent(input$select_all, {
    for(group in names(r_package_groups)) {
      updateCheckboxGroupInput(
        session,
        paste0("pkg_", tolower(gsub(" ", "_", group))),
        selected = r_package_groups[[group]]
      )
    }
  })
  
  observeEvent(input$deselect_all, {
    for(group in names(r_package_groups)) {
      updateCheckboxGroupInput(
        session,
        paste0("pkg_", tolower(gsub(" ", "_", group))),
        selected = character(0)
      )
    }
  })
  
  # Update global variables based on user input
  observe({
    default_users <<- unlist(strsplit(input$users, "[,\\s]+"))  # Fixed pattern
    default_password <<- input$password
  })
  
  # Generate script reactive
  generated_script <- eventReactive(input$generate, {
    withProgress(
      message = 'Generating installation script...',
      value = 0,
      {
        generate_script(
          ubuntu_version = input$ubuntu_version,
          r_version = input$r_version,
          selected_packages = selected_packages()
        )
      }
    )
  })
  
  # Output handlers
  output$bash_script <- renderText({
    generated_script()
  })
  
  output$download <- downloadHandler(
    filename = function() {
      paste0("ubuntu-r-setup-", format(Sys.time(), "%Y%m%d"), ".sh")
    },
    content = function(file) {
      writeLines(generated_script(), file)
    }
  )
  
  # Copy button handler
  observeEvent(input$copy, {
    clipr::write_clip(generated_script())
    showNotification("Script copied to clipboard!", type = "message")
  })
}

shinyApp(ui, server)



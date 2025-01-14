library(DBI)

# Provide the path to the config file/credentials
myhost <- "ip"
credential <- "pgadminpassword"
db_user <-"pgadminuser"


# Connect to the database
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "pgadmin",
  host = myhost,
  port = 5432,
  user = db_user,
  password = credential
)

# Test the connection
print(con)

dbListTables(con)



dplyr::copy_to(con, mtcars, temporary = FALSE)

# exit
dbDisconnect(con)


query <- "SELECT * FROM mtcars"
data <- dbGetQuery(con, query)

# Print the result
print(head(data))


mtcars

query_metadata <- "SELECT * FROM mtcars_meta WHERE table_name = 'mtcars_data'"
metadata <- dbGetQuery(con, query_metadata)
print(metadata)


# Disconnect from the PostgreSQL database
dbDisconnect(con)




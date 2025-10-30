rm(list = ls())

# Load necessary library
library(dplyr)

# Set folder path
folder_path <- "C:\\Users\\Andrea\\OneDrive - Università degli Studi di Sassari\\Desktop\\Dottorato_Sassari\\modello_ACQUAOUNT\\Climate_data_final\\output"

path_output <- "C:\\Users\\Andrea\\OneDrive - Università degli Studi di Sassari\\Desktop\\Dottorato_Sassari\\modello_ACQUAOUNT\\SWB_model_BASIN_II\\Input_data\\climate_data"

# Define prefixes of interest
prefixes <- c("hurs", "pr", "tasmax", "tasmin", "SW_rad", "wind")
region_list <- c("Jordan", "Lebanon1", "Lebanon2","Lebanon3","Sardegna","Tunisia")

# Get list of matching CSV files
file_list <- list.files(folder_path, pattern = paste0("^(", paste(prefixes, collapse = "|"), ")_.*\\.csv$"), full.names = TRUE)

# Initialize an empty list to store data frames


# Loop over files and process them
for (region in region_list) {
  # Extract file name for column renaming
  
  # Extract file paths containing "Tunisia"
  region_files <- grep(region, file_list, value = TRUE)
  data_list <- list()
  for (prfx in prefixes){
    
    file <- grep(prfx,region_files,value=TRUE)
    # Read CSV and select relevant columns
    df <- read.csv(file) %>%
      select(Date, Value) %>%
      rename(!!prfx := Value)
    
    data_list[[prfx]] <- df
  }
  
  # Merge all data frames by the "Date" column
  final_data <- Reduce(function(x, y) full_join(x, y, by = "Date"), data_list)
  final_data<- final_data[-nrow(final_data),]
  final_data$pr[final_data$pr<0]=0 # Convert negative values of precipitation to zero
  
  # Create output file name
  output_file <- file.path(path_output, paste0("climate_data_", region, ".csv"))
  # Export final data frame
  write.csv(final_data, output_file, row.names = FALSE)
}




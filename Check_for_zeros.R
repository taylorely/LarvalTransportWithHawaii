# Quick script to check if a HYCOM file has missing values instead of current data

library(ncdf4
        )
# list all files in the directory
test <- list.files(pattern = 'HYCOM_partials')
# Make an empty data.frame for the files with missing values
zeroFiles <- data.frame(fileName=NA)

# Loop through all the files in the directory and grab the water_u variable, take the mean, and if the mean of that variable is a missing value, it saves the filename to the zeroFiles dataframe
for (i in seq_along(test)) { 
  # read in file
  nc <- nc_open(test[i])
  # get the water_u variable
  u <- ncvar_get(nc, 'water_u')
  # take the mean of the variable. This will be NaN if there is no data
  umean <- mean(u, na.rm=T)
  # If NaN, save filename to dataframe
  if (is.na(umean)) {
    print(paste(test[i], 'has no data!'))
    zeroFiles <- rbind(zeroFiles, test[i])
  }
}

write.csv(zeroFiles, 'HYCOM_missingData.csv', quote = F, row.names = F)
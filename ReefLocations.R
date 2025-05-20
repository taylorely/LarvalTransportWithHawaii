# Author: Johanna Wren, johanna.wren@noaa.gov
# Date: May 19, 2025
# Description: This script uses a shapefile with reef habitat to determine release and settlement points for Taylor Ely's 
#               dispersal modeling project. 

library(sf)
library(dplyr)
library(ggplot2)
library(scales)

# Read in dataset as a spatial object and force it into a polygon file instead of a default multipolygon
# Downloaded from here: https://pacificdata.org/data/dataset/global-distribution-of-coral-reefs/resource/3ad70ea1-6c69-4719-9257-0aec9738bc53
test <- sf::read_sf('~/Downloads/14_001_WCMC008_CoralReefs2018_v4_1/01_Data/WCMC008_CoralReef2018_Py_v4_1.shp')
# Define crop area
# I did one for east of 180 and one for west just becuase that's how the shapefile is set up it's easier. We are not missing out on any habitat by doing this
box <- c(xmin=-180, xmax=-150, ymin=15, ymax=35) # hawaiian archipelago
#box <- c(xmin=120, xmax=180, ymin=0, ymax=45) # west of 180
#box2 <- c(xmin=-158.5, xmax=-157.5, ymin=21.2, ymax=22) # oahu
# Crop into area of interest for easier handling of the file
test_crop <- test %>% 
  st_make_valid() %>% #make sure to fix some erroneous polygons that keep us from being able to crop
  st_crop(y=box)

# Plot to see what the cropped area looks like
test_crop %>% 
  ggplot() + 
    geom_sf() + 
    coord_sf() + 
    theme_bw()

# First we need to merge overlaping polygons since they are classified after different habitat
# Then I'm adding the area for each polygon so we can use that to scale number of release points and/or remove small polygons
reefSimple <- st_union(test_crop) %>%   # merge overlapping polygons
  st_cast("POLYGON") %>%   # change from multipolygon to polygon to remove nesting in the data
  st_as_sf() %>%  # make it a sf object again so we can keep working with it
  mutate(area_m2 = as.numeric(st_area(.)), ID = 1:n()) %>% # add area of each polygon. We'll use this to scale the number of release points and to remove small reefs
  #filter(area_m2 > 100000) %>%    #filters out smaller polygons. Doesn't work great as it removed all reefs on big island, but could be useful in areas with tons of little reefs
  st_simplify(dTolerance = 300) %>%  # simplify (remove detail) the polygons for a cruder outline. This does remove some smaller polygons. Play around with the number here to get the result you want
  st_cast('POLYGON') %>%   # turn it back into polygons
  filter(!st_is_empty(.)) %>% # remove all the empty polygons created by simplify
  st_as_sf() %>%   # turn back into an sf object
  mutate(releaseLocs = round(rescale(.$area_m2, to=c(1,10)))) # make a new column with number of release locations scaled after the area of the polygon. You can change the max number for each polygon to keep your total release locations from ballooning
# Plot to see what the simplified area looks like
reefSimple %>% 
  ggplot() + 
  geom_sf() + 
  coord_sf() + 
  theme_bw()

# sample the area for equally spaced points
pointsSample <- reefSimple %>% 
  st_sample(type='regular', size = .$releaseLocs) %>%  # this samples each polygon and puts releaseLoc number or release points in each polygon, evenly spaced
  st_set_crs(st_crs(reef))   # need to set the crs for this so I can plot it, this line isn't necessary if you just want to save the output
# Plot to see what the simplified area looks like
pointsSample %>% 
  ggplot() + 
  geom_sf() + 
  coord_sf() + 
  theme_bw() 

# Save release locations file
pointsRelease <- as.data.frame(st_coordinates(pointsSample))
write.csv(pointsRelease, 'ReefLocations.csv', quote = F, row.names = F)



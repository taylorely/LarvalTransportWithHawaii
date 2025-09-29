import xarray as xr
import netCDF4 as nc
from datetime import timedelta, datetime
import pandas as pd

# Load HYCOM dataset metadata
myDat = xr.open_dataset('https://apdrc.soest.hawaii.edu/erddap/griddap/hawaii_soest_e9ba_92b1_0bcd')

#make empty list for what days have missing data
missing = []

# Start looping through time (every 3h)
#2920 for range of 1 year 29200 for 10 years
start_date = datetime(1993, 1, 6, 0, 0, 0)
for td in (start_date + timedelta(hours=3*it) for it in range(2)):  # change the range here to the number of files you want to download. One year would be 365*8 since they are 3h files, so 8 each day
 
    # subset but check to see if it isn't missing data
    try:
    	test = myDat[['water_u', 'water_v']].sel(time=td.strftime("%Y-%m-%dT%H:%M:%S"), LEV=[2,6,20,60,250])
    except Exception as e:
    	print(''.join([td.strftime('%Y%m%d%H'), ' is missing data']))
	
    if len(test) > 0:
    	# change from 180/-180 to 0-360 se we can crop over the dateline
    	test = test.assign_coords(longitude=((360 + (test.longitude % 360)) % 360))
    	test = test.roll(longitude=int(len(test['longitude']) / 2),roll_coords=True)

   		# Subset for the lon and lat you want
    	test2 = test.sel(longitude=slice(100,250), latitude=slice(0,45))

    	# Renaming the depth variable becuase I really don't like LEV
    	test2.rename({'LEV' : 'depth'})

    	# Save data
    	test2.to_netcdf(''.join(['/Volumes/LAPS/redo_HYCOM/HYCOM_', td.strftime('%Y%m%d%H'), '.nc']))

    else:
    	missing.append(''.join([td.strftime('%Y%m%d%H'), ' is missing data']))

#save missing files to csv
missingdays = pd.DataFrame(missing)
missingdays.to_csv('missingdaysin1993.csv', index=False)
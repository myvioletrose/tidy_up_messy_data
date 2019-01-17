# this script is a perfect example of tidying up messy data using tidyverse
readxl - read xlsx / 
dplyr - data wrangling / 
purrr - mapping, nesting / 
stringr - string manipulation / 
lubridate - date manipulation / 
ggplot2 - visualization 

# objective
1) extract, clean and then generate insights (Average Daily Rate) for each "RATE PLAN" by date for each file
2) inside the "data/input" folder, there are multiple Excel files, there are multiple Excel files, i.e. "detailedReservations_Report_2018-02-06.xlsx", "detailedReservations_Report_2018-02-07.xlsx", "detailedReservations_Report_2018-02-08.xlsx". These files are identical, but we use them for illustrative purpose here.
3) this script is designed to run on multiple xlsx files inside the same directory at the same time!

# there are three caveats
1) we need to extract "date" from the "ARRIVAL" and "DEPARTURE" columns, e.g. if "ARRIVAL" == "Feb 04, 2018", whereas "DEPARTURE" == "Feb 07, 2018", then we need to extract "2018-02-04", "2018-02-05", and "2018-02-06"
2) we need to extract numbers from the "DAILY RATES" column; however, the data is formatted as string, and multiple values are put together separated by comma, e.g. "143.0, 251.0, 303.0". Each value would correspond to an individual date that we need to extract from first step
3) there are repeated/duplicated rows for a "RATE PLAN", e.g. there is a row where we see "ARRIVAL" == "Feb 04, 2018", and "DEPARTURE" == "Feb 07, 2018"; however, there's another row where we just see "ARRIVAL" == "Feb 04, 2018", and "DEPARTURE" == "Feb 05, 2018". The "DAILY RATES" are the same, and we should ignore the second row with less data.

# AT THE END, this script will clean up this messy data and generate
1) a tidy csv file for each input file (dumped it back in "data/output" folder), where we have only "date", "daily.rates", & "rate plan"
2) a beautiful ggplot for each input file (dumpted it in "figure" folder), where everything is summarized in one picture!

### below script is a perfect example of tidying up messy data using tidyverse
# readxl - read xlsx
# dplyr - data wrangling
# purrr - mapping
# tidyr - nesting
# stringr - string manipulation
# lubridate - date manipulation
# ggplot2 - visualization

### inside the "data/input" folder, there are multiple Excel files, i.e. "detailedReservations_Report_2018-02-06.xlsx", "detailedReservations_Report_2018-02-07.xlsx", "detailedReservations_Report_2018-02-08.xlsx"
# these files are identical, but we use them for illustrative purpose here
# the objective is to extract, clean and then generate insights (Average Daily Rate) for each "RATE PLAN" by date for each file
# this script is designed to run on multiple xlsx files inside the same directory at the same time!

### there are three caveats, 
# 1) we need to extract "date" from the "ARRIVAL" and "DEPARTURE" columns, e.g. if "ARRIVAL" == "Feb 04, 2018", whereas "DEPARTURE" == "Feb 07, 2018", then we need to extract "2018-02-04", "2018-02-05", and "2018-02-06"
# 2) we need to extract numbers from the "DAILY RATES" column; however, the data is formatted as string, and multiple values are put together separated by comma, e.g. "143.0, 251.0, 303.0". Each value would correspond to an individual date that we need to extract from first step
# 3) there are repeated/duplicated rows for a "RATE PLAN", e.g. there is a row where we see "ARRIVAL" == "Feb 04, 2018", and "DEPARTURE" == "Feb 07, 2018"; however, there's another row where we just see "ARRIVAL" == "Feb 04, 2018", and "DEPARTURE" == "Feb 05, 2018". The "DAILY RATES" are the same, and we should ignore the second row with less data.

### at the end, this script will clean up this messy data and generate
# 1) a tidy csv file for each input file (dumped it back in "data/output" folder), where we have only "date", "daily.rates", & "rate plan"
# 2) a beautiful ggplot for each input file (dumpted it in "figure" folder), where everything is summarized in one picture!


##################################
#### set up working directory ####
##################################
current_wd <- getwd()

#######################
#### load packages ####
#######################
options(warn = -1)
if(!require(tidyverse)){install.packages("tidyverse");require(tidyverse)}

# if(!require(readxl)){install.packages("readxl");require(readxl)}
# if(!require(dplyr)){install.packages("dplyr");require(dplyr)}
# if(!require(purrr)){install.packages("purrr");require(purrr)}
# if(!require(stringr)){install.packages("stringr");require(stringr)}
# if(!require(lubridate)){install.packages("lubridate");require(lubridate)}
# if(!require(ggplot2)){install.packages("ggplot2");require(ggplot2)}

##################
## read file(s) ##
##################
setwd("../"); setwd("data/input")
xlsx.files <- grep(pattern = ".xlsx", x = dir(), ignore.case = T, value = T)
df.list <- map(xlsx.files, readxl::read_excel)
names(df.list) <- purrr::set_names(xlsx.files %>%
                                           stringr::str_replace_all(pattern = ".xlsx", 
                                                                    replacement = ""))
setwd(current_wd)

########################################################
##### change header to lower case, add "id" column #####
########################################################
for(i in 1:length(df.list)){
        names(df.list[[i]]) <- tolower(names(df.list[[i]]))
        df.list[[i]]$id <- paste0("id", 1:nrow(df.list[[i]]))
}

######################################################
###### get the id `rate plan` matching table(s) ######
######################################################
id.rate_plan.match <- list()

for(i in 1:length(df.list)){
        id.rate_plan.match[[i]] <- select(df.list[[i]], id, `rate plan`)
}

########################################
##### start nesting by `rate plan` #####
########################################
df.nested <- list()

for(i in 1:length(df.list)){
        df.nested[[i]] <- df.list[[i]] %>%
                tidyr::nest(-`rate plan`)
}

##################################
### data manipulation function ###
##################################
data.manipulation <- function(x) {
        
        date.obj <- subset(x, select = c(id, arrival, departure)) %>%
                dplyr::mutate(a = lubridate::mdy(arrival),
                       d = lubridate::mdy(departure)) %>%
                group_by(id) %>%
                dplyr::mutate(date.seq = list(seq(from = a, to = d -1, by = "day"))) %>%
                select(id, date.seq) %>%
                ungroup()
        
        daily.rate.obj <- subset(x, select = c(id, `daily rates`)) %>%
                group_by(id) %>%
                dplyr::mutate(dr = strsplit(`daily rates`, ", ")) %>%  # make sure the separator is comma
                select(id, dr) %>%
                ungroup()
        
        df <- inner_join(date.obj, daily.rate.obj)
        
        id <- rep(df$id, sapply(df$date.seq, length))
        
        date <- as.Date(flatten_dbl(df$date.seq), origin = "1970-01-01")
        
        options(digits = 9)
        daily.rates <- as.numeric(flatten_chr(df$dr))
        
        df <- data.frame(id, date, daily.rates) %>%
                arrange(date)
        
        df
}

#####################################################################################
########### apply data manipulation function to each nested tibble object ###########
## save an output in csv for each input xlsx, and then produce a bar plot for each ##
#####################################################################################
for(i in 1:length(df.nested)){
        
        x <- purrr::map(df.nested[[i]]$data, data.manipulation)
        names(x) <- purrr::set_names(df.nested[[i]]$`rate plan`)
        y <- bind_rows(x) %>%
                inner_join(id.rate_plan.match[[i]]) %>%
                select(., -id) %>%
                arrange(`rate plan`, date)
        
        # set output wd to "data/output"
        setwd("../"); setwd("data/output")
        write.csv(y, file = paste0(names(df.list)[i], ".csv"), row.names = F, append = F)
        
        ADR.chart <- y %>% group_by(date, `rate plan`) %>%
                summarise(adr = mean(daily.rates),
                          date.count = n()) %>%
                ungroup() %>%
                ggplot(aes(date, adr)) +
                geom_bar(stat = "identity", aes(fill = `rate plan`)) +
                facet_wrap(~ `rate plan`, scales = "free_x", ncol = 4) + 
                # theme(legend.position = "none",
                #       plot.title = element_text(hjust = 0.5)) +
                theme(strip.text = element_text(size = 7.5)) +
                ggtitle("Rate Plan: ADR by date") + 
                labs(x = "", y = "") +
                scale_fill_discrete(guide = FALSE) +
                scale_y_continuous(labels = scales::dollar) 
        
        # set output wd to "figure"
        setwd(current_wd); setwd("../"); setwd("figure")
        ggsave(filename = paste0(names(df.list)[i], ".png"),
               plot = ADR.chart, 
               width = 11.7,
               height = 8.3,
               units = "in")  # save in standard A4 size
        
        setwd(current_wd)
}














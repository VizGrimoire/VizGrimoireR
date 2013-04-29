## Copyright (C) 2012, 2013 Bitergia
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## This file is a part of the vizGrimoire.R package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo San Felix <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --no-restore --no-save < mls-milestone0.R
## or
##  R CMD BATCH mls-milestone0.R
##

library("vizgrimoire")


## Complete with zeros samples by selected period
completeZeroPeriod2 <- function (data, period, start, end, metric='unknow') {
    
    if (!(period %in% c('days','weeks','months','years')))
        stop (paste("WRONG PERIOD", period))
    
    nperiod = 1 # sql resolution, days
    
    cur_period = GetPeriod(period,as.Date(conf$str_startdate))
    cur_period_metric_val = 0
    for (i in 1:nrow(new_data)) {
        metric_val <- new_data[i,2]
        date <- new_data[i,3]
        date_period <- GetPeriod(period,date)
        
        if (date_period != cur_period) {
            # Store last period data 
            grouped_data[['id']] <- c(grouped_data[['id']], past_date)
            grouped_data[['date']] <- c(grouped_data[['date']],
                    GetDateText(period, past_date))
            grouped_data[[metric]] <- c(grouped_data[[metric]],
                    cur_period_metric_val)
            cur_period_metric_val = metric_val
            cur_period = date_period
        } else {
            cur_period_metric_val = cur_period_metric_val + metric_val
            past_date = date
        }
    }
    if (date_period == cur_period) {
        grouped_data[['id']] <- c(grouped_data[['id']], date)
        grouped_data[[metric]] <- c(grouped_data[[metric]], cur_period_metric_val)
        grouped_data[['date']] <- c(grouped_data[['date']],
                GetDateText(period, date))
    }
    
    grouped_data<-data.frame(id=grouped_data[['id']],metric=grouped_data[[metric]],
            date=grouped_data[['date']],stringsAsFactors=FALSE)
    colnames(grouped_data)[2]<-metric
    
    return (grouped_data)
}

endDST <- function (date) {
    value = FALSE
    newdate = as.POSIXlt(as.numeric(date)+ 60*60*24, origin="1970-01-01")
    if (newdate$hour>0) value = TRUE   
    return (value)
}

startDST <- function (date) {
    value = FALSE
    newdate = as.POSIXlt(as.numeric(date)+ 60*60*24, origin="1970-01-01")
    if (date$mday == newdate$mday) value = TRUE   
    return (value)
}

# Week of the year as decimal number (00–53) as defined in ISO 8601
completeZeroPeriodIdsWeeks <- function (data, start, end) {
    first_week = format(start, "%Y-%V")
    last = ceiling (difftime(end, start,units="weeks"))
    
    samples <- list('id'=c(1:last))     
    # Monday not Sunday
    new_date = as.POSIXlt(as.Date(start)-start$wday+1)
    for (i in 1:last) {                
        samples$unixtime[i] = as.numeric(new_date)
        samples$date[i]=format(new_date)
        samples$week[i]=format(format(new_date, "%G%V"))
        new_date = as.POSIXlt(as.Date(new_date)+7)
    }
    
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0
    
    print(completedata)        
    stop()
    
    return(completedata)
    
}

# Work in seconds but supported days,weeks,mothns and years for now
completeZeroPeriodIdsDays <- function (data, start, end) {        
    # units should be one of “auto”, “secs”, “mins”, “hours”, “days”, “weeks”
    last = ceiling (difftime(end, start,units=period))
    # months and years are simple math
    print(paste("MONTHS:",(end$year*12)+end$mon,(start$year*12)+start$mon))
    print(paste("YEARS:",end$year,start$year))
    
    samples <- list('id'=c(1:last)) 
    lastdate = start
    dst = FALSE
    hour.secs = 60*60
    day.secs = hour.secs*24
    for (i in 1:last) {        
        samples$unixtime[i] = as.numeric(start)+((i-1)*day.secs)
        if (startDST(lastdate)) dst = TRUE
        else if (endDST(lastdate)) dst = FALSE
        if (dst) samples$unixtime[i] = samples$unixtime[i] + hour.secs
        lastdate = as.POSIXlt(samples$unixtime[i], origin="1970-01-01")                   
        samples$date[i]=format(lastdate)
    }    
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0
    print(completedata)
    stop()
    return (completedata)
}

completeZeroPeriodIds <- function (data, period, startdate, enddate){           
    start = as.POSIXlt(startdate)
    end = as.POSIXlt(enddate)    
    if (period == "days") {
        return (completeZeroPeriodIdsDays(data, start, end))
    }    
    if (period == "weeks") {
        return (completeZeroPeriodIdsWeeks(data, start, end))
    }
}

## Group daily samples by selected period
completePeriodIds <- function (data, period, conf) {
    
    if (length(data) == 0) {
        # TODO: broken, only works for commit metric
        data <- data.frame(id=numeric(0), commits=numeric(0))
    }
    new_data <- completeZeroPeriodIds(data, period, conf$str_startdate, conf$str_enddate)
    # new_data$week <- as.Date(conf$str_startdate) + new_data$id * period
    # new_data$date  <- toTextDate(GetYear(new_data$week), GetMonth(new_data$week)+1)
    new_data[is.na(new_data)] <- 0
    new_data <- new_data[order(new_data$id), ]
    
    return (new_data)
}


conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)

# period of time
if (conf$granularity == 'months'){
   period = 'month'
   nperiod = 31
}
if (conf$granularity == 'weeks'){
   period = 'week'
   nperiod = 7
}
if (conf$granularity == 'days'){
       period = 'day'
       nperiod = 1
}

identities_db = conf$identities_db

# dates
startdate <- conf$startdate
enddate <- conf$enddate

# Aggregated data
if (conf$reports == 'countries'){
    static_data <- mls_static_info(startdate, enddate, conf$reports)
} else{
    static_data <- mls_static_info(startdate, enddate)
}
latest_activity7 <- last_activity_mls(7)
latest_activity30 <- last_activity_mls(30)
latest_activity90 <- last_activity_mls(90)
latest_activity365 <- last_activity_mls(365)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity365)
createJSON (static_data, paste("data/json/mls-static.json",sep=''))

# Mailing lists
query <- new ("Query", sql = "select distinct(mailing_list) from messages")
mailing_lists <- run(query)

if (is.na(mailing_lists$mailing_list)) {
    print ("URL Mailing List")
    query <- new ("Query",
                  sql = "select distinct(mailing_list_url) from messages")
    mailing_lists <- run(query)
    mailing_lists_files <- run(query)
    mailing_lists_files$mailing_list = gsub("/","_",mailing_lists$mailing_list)
    # print (mailing_lists)
    createJSON (mailing_lists_files, "data/json/mls-lists.json")
    repos <- mailing_lists_files$mailing_list
    createJSON(repos, "data/json/mls-repos.json")	
} else {
    print (mailing_lists)
    createJSON (mailing_lists, "data/json/mls-lists.json")
	repos <- mailing_lists$mailing_list;
	createJSON(repos, "data/json/mls-repos.json")	
}

if (conf$reports == 'countries') {
    countries <- countries_names(identities_db, startdate, enddate) 
    createJSON (countries, paste("data/json/mls-countries.json",sep=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        data <- mlsEvolCountries(identities_db, country, nperiod, startdate, enddate)
        data <- completePeriod(data, nperiod, conf)        
        createJSON (data, paste("data/json/",country,"-mls-evolutionary.json",sep=''))
        
        data <- mlsStaticCountries(identities_db, country, startdate, enddate)
        createJSON (data, paste("data/json/",country,"-mls-static.json",sep=''))
    }
}

for (mlist in mailing_lists$mailing_list) {
    
    # Evol data
    data<-mlsEvolList(mlist, nperiod, startdate, enddate)
    data <- completePeriod(data, nperiod, conf)
    data[is.na(data)] <- 0
    data <- data[order(data$id),]
    
    listname_file = gsub("/","_",mlist)
    
    # TODO: Multilist approach. We will obsolete it in future
    createJSON (data, paste("data/json/mls-",listname_file,"-evolutionary.json",sep=''))
    # Multirepos filename
    createJSON (data, paste("data/json/",listname_file,"-mls-evolutionary.json",sep=''))
        
    # Static data
    data<-mlsStaticList(mlist, nperiod, startdate, enddate)
    # TODO: Multilist approach. We will obsolete it in future
	createJSON (data, paste("data/json/mls-",listname_file,"-static.json",sep=''))
	# Multirepos filename
	createJSON (data, paste("data/json/",listname_file,"-mls-static.json",sep=''))    
}

if (conf$reports == 'countries'){
    data <- mlsEvol(period, startdate, enddate, conf$reports)
} else {
    data <- mlsEvol(period, startdate, enddate)
}
print(data)
data <- completePeriodIds(data, conf$granularity, conf)
createJSON (data, paste("data/json/mls-evolutionary.json"))

stop()

# Top senders
# top_senders_data <- top_senders_wo_affs(c("-Bot"), identities_db, startdate, enddate)
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders(0, conf$startdate, conf$enddate,identites_db)
top_senders_data[['senders.last year']]<-top_senders(365, conf$startdate, conf$enddate,identites_db)
top_senders_data[['senders.last month']]<-top_senders(31, conf$startdate, conf$enddate,identites_db)

createJSON (top_senders_data, "data/json/mls-top.json")

# People list
# query <- new ("Query", 
# 		sql = "select email_address as id, email_address, name, username from people")
# people <- run(query)
# createJSON (people, "data/json/mls-people.json")


# Companies information
if (conf$reports == 'companies'){
    
    company_names = companies_names(identities_db, startdate, enddate)
    # company_names = companies_names_wo_affs(c("-Bot", "-Individual", "-Unknown"), identities_db, startdate, enddate)

    createJSON(company_names$name, "data/json/mls-companies.json")
   
    for (company in company_names$name){       
        print (company)
        company_name = paste("'",company,"'",sep="")
        post_posters = company_posts_posters (company_name, identities_db, nperiod, startdate, enddate)
        post_posters <- completePeriod(post_posters, nperiod, conf)        
        createJSON(post_posters, paste("data/json/",company,"-mls-evolutionary.json", sep=""))

        top_senders = company_top_senders (company_name, identities_db, period, startdate, enddate)
        createJSON(top_senders, paste("data/json/",company,"-mls-top-senders.json", sep=""))

        static_info = company_static_info(company_name, identities_db, startdate, enddate)
        createJSON(static_info, paste("data/json/",company,"-mls-static.json", sep=""))
    }
}

# Demographics

demos <- new ("Demographics","mls",6)
demos$age <- as.Date(conf$str_enddate) - as.Date(demos$firstdate)
demos$age[demos$age < 0 ] <- 0
aux <- data.frame(demos["id"], demos["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, "data/json/mls-demographics-aging.json")

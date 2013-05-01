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

completeZeroPeriodIdsYears <- function (data, start, end) {    
    last = end$year - start$year  + 1   
    samples <- list('id'=c(1:last))    
    
    new_date = start
    new_date$mday = 1
    new_date$mon = 0
    for (i in 1:last) {
        # convert to Date to remove DST from start of month
        samples$unixtime[i] = as.numeric(as.POSIXlt(as.Date(new_date)))
        samples$date[i]=format(new_date)
        samples$year[i]=(1900+new_date$year)*12
        new_date$year = new_date$year + 1
    }
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0    
    print(completedata)
    stop()    
    return(completedata)    
}


completeZeroPeriodIdsMonths <- function (data, start, end) {    
    start_month = ((1900+start$year)*12)+start$mon+1
    end_month =  ((1900+end$year)*12)+end$mon+1 
    last = end_month - start_month + 1 
    
    samples <- list('id'=c(1:last))    
    new_date = start
    new_date$mday = 1    
    for (i in 1:last) {
        # convert to Date to remove DST from start of month
        samples$unixtime[i] = as.numeric(as.POSIXlt(as.Date(new_date)))
        samples$date[i]=format(new_date)
        samples$month[i]=((1900+new_date$year)*12)+new_date$mon+1
        new_date$mon = new_date$mon + 1
    }        
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0    
    print(completedata)
    stop()    
    return(completedata)    
}


# Week of the year as decimal number (01–53) as defined in ISO 8601
completeZeroPeriodIdsWeeks <- function (data, start, end) {
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

# Work in seconds as a future investment
completeZeroPeriodIdsDays <- function (data, start, end) {        
    # units should be one of “auto”, “secs”, “mins”, “hours”, “days”, “weeks”
    last = ceiling (difftime(end, start,units=period)) + 1
    
    samples <- list('id'=c(1:last)) 
    lastdate = start
    start_dst = start$isdst
    dst = start_dst
    dst_offset_hour = 0
    hour.secs = 60*60
    day.secs = hour.secs*24
    
    for (i in 1:last) {        
        samples$unixtime[i] = as.numeric(start)+((i-1)*day.secs)
        new_date = as.POSIXlt(samples$unixtime[i],origin="1970-01-01") 
        if (new_date$isdst != dst) {
            dst = new_date$isdst
            if (dst == start_dst) offset_hour = 0
            else if (start_dst == 1) dst_offset_hour = hour.secs
            else if (start_dst == 0) dst_offset_hour = -hour.secs
        }
        samples$unixtime[i] = samples$unixtime[i] + dst_offset_hour
        lastdate = as.POSIXlt(samples$unixtime[i], origin="1970-01-01")                   
        # samples$datedbg[i]=format(lastdate,"%H:%M %d-%m-%y")
        samples$date[i]=format(lastdate)
    }
    completedata <- merge (data, samples, all=TRUE, stringsAsFactors=FALSE)
    completedata[is.na(completedata)] <- 0
    return (completedata)
}

completeZeroPeriodIds <- function (data, period, startdate, enddate){           
    start = as.POSIXlt(startdate)
    end = as.POSIXlt(enddate)    
    if (period == "days") {
        return (completeZeroPeriodIdsDays(data, start, end))
    }    
    else if (period == "weeks") {
        return (completeZeroPeriodIdsWeeks(data, start, end))
    }
    else if (period == "months") {
        return (completeZeroPeriodIdsMonths(data, start, end))
    }
    else if (period == "years") {
        return (completeZeroPeriodIdsYears(data, start, end))
    } 
    else {
        stop (paste("Unknow period", period))
    } 

}

## Group daily samples by selected period
completePeriodIds <- function (data, period, conf) {
    
    if (length(data) == 0) {
        data <- data.frame(id=numeric(0))
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
# Sys.setenv( TZ="Etc/GMT+8" )

# period of time
if (conf$granularity == 'years'){
   period = 'year'
   nperiod = 365
} else if (conf$granularity == 'months'){
   period = 'month'
   nperiod = 31
} else if (conf$granularity == 'weeks'){
   period = 'week'
   nperiod = 7
} else if (conf$granularity == 'days'){
       period = 'day'
       nperiod = 1
} else {
    stop(paste("Incorrect period:",conf$granularity))
}

identities_db = conf$identities_db

# dates
startdate <- conf$startdate
enddate <- conf$enddate

#
# GLOBAL
#
rfield = reposField()

data <- mlsEvol(rfield, period, startdate, enddate, identities_db, conf$reports)
data <- completePeriodIds(data, conf$granularity, conf)
createJSON (data, paste("data/json/mls-evolutionary.json"))

static_data <- mlsStatic(rfield, startdate, enddate, conf$reports)
latest_activity7 <- lastActivity(7)
latest_activity30 <- lastActivity(30)
latest_activity90 <- lastActivity(90)
latest_activity365 <- lastActivity(365)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity365)
createJSON (static_data, paste("data/json/mls-static.json",sep=''))


if (conf$reports == 'repositories') {
    repos <- reposNames(rfield, startdate, enddate)
    createJSON (repos, "data/json/mls-lists.json")
    repos <- repos$mailing_list
    createJSON(repos, "data/json/mls-repos.json")	    
    
    print (repos)
    
    for (repo in repos) {    
        # Evol data
        data<-mlsEvolRepos(rfield, repo, period, startdate, enddate)
        data <- completePeriodIds(data, conf$granularity, conf)        
        listname_file = gsub("/","_",repo)
        
        # TODO: Multilist approach. We will obsolete it in future
        createJSON (data, paste("data/json/mls-",listname_file,"-evolutionary.json",sep=''))
        # Multirepos filename
        createJSON (data, paste("data/json/",listname_file,"-mls-evolutionary.json",sep=''))
        
        top_senders = repoTopSenders (repo, identities_db, startdate, enddate)
        createJSON(top_senders, paste("data/json/",repo,"-mls-top-senders.json", sep=""))        
        
        # Static data
        data<-mlsStaticRepos(rfield, repo, startdate, enddate)
        # TODO: Multilist approach. We will obsolete it in future
    	createJSON (data, paste("data/json/mls-",listname_file,"-static.json",sep=''))
    	# Multirepos filename
    	createJSON (data, paste("data/json/",listname_file,"-mls-static.json",sep=''))    
    }
}

if (conf$reports == 'countries') {
    countries <- countriesNames(identities_db, startdate, enddate) 
    createJSON (countries, paste("data/json/mls-countries.json",sep=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        data <- mlsEvolCountries(country, identities_db, period, startdate, enddate)
        data <- completePeriodIds(data, conf$granularity, conf)        
        createJSON (data, paste("data/json/",country,"-mls-evolutionary.json",sep=''))
        
        top_senders = countryTopSenders (country, identities_db, startdate, enddate)
        createJSON(top_senders, paste("data/json/",country,"-mls-top-senders.json", sep=""))        
        
        data <- mlsStaticCountries(country, identities_db, startdate, enddate)
        createJSON (data, paste("data/json/",country,"-mls-static.json",sep=''))
    }
}

if (conf$reports == 'companies'){    
    companies = companiesNames(identities_db, startdate, enddate)
    createJSON(companies, "data/json/mls-companies.json")
   
    for (company in companies){       
        print (company)
        sent.senders = mlsEvolCompanies(company, identities_db, period, startdate, enddate)
        # sent.senders <- completePeriod(sent.senders, nperiod, conf): Nice unixtime!!!
        sent.senders <- completePeriodIds(sent.senders, conf$granularity, conf)
        createJSON(sent.senders, paste("data/json/",company,"-mls-evolutionary.json", sep=""))

        top_senders = companyTopSenders (company, identities_db, startdate, enddate)
        createJSON(top_senders, paste("data/json/",company,"-mls-top-senders.json", sep=""))

        data = mlsStaticCompanies(company, identities_db, startdate, enddate)
        createJSON(data, paste("data/json/",company,"-mls-static.json", sep=""))
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

# Tops
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders(0, conf$startdate, conf$enddate,identities_db,c("NULL"))
top_senders_data[['senders.last year']]<-top_senders(365, conf$startdate, conf$enddate,identities_db,c("NULL"))
top_senders_data[['senders.last month']]<-top_senders(31, conf$startdate, conf$enddate,identities_db,c("NULL"))

createJSON (top_senders_data, "data/json/mls-top.json")

# People list
# query <- new ("Query", 
# 		sql = "select email_address as id, email_address, name, username from people")
# people <- run(query)
# createJSON (people, "data/json/mls-people.json")

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
## This file is a part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## AuxiliaryMLS.R
##
## Queries for MLS data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Luis Cañas-Díaz <lcanas@bitergia.com>

GetSQLGlobal <- function(date, fields, tables, filters, start, end) {        
    sql = paste ('SELECT ', fields)
    sql = paste(sql,'FROM', tables)
    sql = paste(sql,'WHERE',date,'>=',start,'AND',date,'<',end)
    if (filters != "") {
        sql = paste(sql,' AND ',filters)
    }
    return(sql)    
}

GetSQLPeriod <- function(period, date, fields, tables, filters, start, end) {
    
    kind = c('year','month','week','day')
    iso_8601_mode = 3
    if (period == 'day') {
        # Remove time so unix timestamp is start of day    
        sql = paste('SELECT UNIX_TIMESTAMP(DATE(',date,')) AS unixtime, ')
    } else if (period == 'week') {
        sql = paste('SELECT ')
        sql = paste(sql, 'YEARWEEK(',date,',',iso_8601_mode,') AS week, ')
    } else if (period == 'month') {
        sql = paste('SELECT YEAR(',date,')*12+MONTH(',date,') AS month, ')
    }  else if (period == 'year') {
        sql = paste('SELECT YEAR(',date,')*12 AS year, ')
    } else {
        stop(paste("Wrong period",period))
    }
    # sql = paste(sql, 'DATE_FORMAT (',date,', \'%d %b %Y\') AS date, ')
    sql = paste(sql, fields)
    sql = paste(sql,'FROM', tables)
    sql = paste(sql,'WHERE',date,'>=',start,'AND',date,'<',end)
    if (filters != "") {
        sql = paste(sql,' AND ',filters)
    }    
    if (period == 'year') {
        sql = paste(sql,' GROUP BY YEAR(',date,')')
        sql = paste(sql,' ORDER BY YEAR(',date,')')
    }
    else if (period == 'month') {
        sql = paste(sql,' GROUP BY YEAR(',date,'),MONTH(',date,')')
        sql = paste(sql,' ORDER BY YEAR(',date,'),MONTH(',date,')')
    }
    else if (period == 'week') {
        sql = paste(sql,' GROUP BY YEARWEEK(',date,',',iso_8601_mode,') ')
        sql = paste(sql,' ORDER BY YEARWEEK(',date,',',iso_8601_mode,') ')        
    }
    else if (period == 'day') {
        sql = paste(sql,' GROUP BY YEAR(',date,'),DAYOFYEAR(',date,')')
        sql = paste(sql,' ORDER BY YEAR(',date,'),DAYOFYEAR(',date,')')                
    }
    else {
        stop(paste("PERIOD: ",period,' not supported'))
    }
    return(sql)
}

GetTablesOwnUniqueIds <- function() {
    return ('messages m, messages_people mp, people_upeople pup')
}

# Using senders only here!
GetFiltersOwnUniqueIds <- function () {
    return ('m.message_ID = mp.message_id AND 
             mp.email_address = pup.people_id AND 
             mp.type_of_recipient=\'From\'') 
}

GetTablesCountries <- function(i_db) {
    return (paste(GetTablesOwnUniqueIds(),', 
                  ',i_db,'.countries c,
                  ',i_db,'.upeople_countries upc',sep=''))
}

GetFiltersCountries <- function() {
    return (paste(GetFiltersOwnUniqueIds(),' AND
                  pup.upeople_id = upc.upeople_id AND
                  upc.country_id = c.id'))
}

GetTablesCompanies <- function(i_db) {
    return (paste(GetTablesOwnUniqueIds(),',
                  ',i_db,'.companies c,
                  ',i_db,'.upeople_companies upc',sep=''))
}

GetFiltersCompanies <- function() {
    return (paste(GetFiltersOwnUniqueIds(),' AND
                  pup.upeople_id = upc.upeople_id AND
                  upc.company_id = c.id AND
                  m.first_date >= upc.init AND
                  m.first_date < upc.end'))
}

completeZeroPeriodIdsYears <- function (data, start, end) {    
    last = end$year - start$year  + 1   
    samples <- list('id'=c(0:(last-1)))    
    
    new_date = start
    new_date$mday = 1
    new_date$mon = 0
    for (i in 1:last) {
        # convert to Date to remove DST from start of month
        samples$unixtime[i] = toString(as.numeric(as.POSIXlt(as.Date(new_date))))
        samples$date[i]=format(new_date, "%b %Y")
        samples$year[i]=(1900+new_date$year)*12
        new_date$year = new_date$year + 1
    }
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0    
    print(completedata)    
    return(completedata)    
}


completeZeroPeriodIdsMonths <- function (data, start, end) {    
    start_month = ((1900+start$year)*12)+start$mon+1
    end_month =  ((1900+end$year)*12)+end$mon+1 
    last = end_month - start_month + 1 
    
    samples <- list('id'=c(0:(last-1)))
    new_date = start
    new_date$mday = 1    
    for (i in 1:last) {
        # convert to Date to remove DST from start of month
        samples$unixtime[i] = toString(as.numeric(as.POSIXlt(as.Date(new_date))))
        samples$date[i]=format(new_date, "%b %Y")
        samples$month[i]=((1900+new_date$year)*12)+new_date$mon+1
        new_date$mon = new_date$mon + 1
    }        
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0    
    print(completedata)    
    return(completedata)    
}


# Week of the year as decimal number (01–53) as defined in ISO 8601
completeZeroPeriodIdsWeeks <- function (data, start, end) {
    last = ceiling (difftime(end, start,units="weeks"))
    
    samples <- list('id'=c(0:(last-1)))     
    # Monday not Sunday
    new_date = as.POSIXlt(as.Date(start)-start$wday+1)
    for (i in 1:last) {                
        samples$unixtime[i] = toString(as.numeric(new_date))
        samples$date[i]=format(new_date, "%b %Y")
        samples$week[i]=format(format(new_date, "%G%V"))
        new_date = as.POSIXlt(as.Date(new_date)+7)
    }
    
    completedata <- merge (data, samples, all=TRUE)
    completedata[is.na(completedata)] <- 0    
    print(completedata)        
    return(completedata)    
}

# Work in seconds as a future investment
completeZeroPeriodIdsDays <- function (data, start, end) {        
    # units should be one of “auto”, “secs”, “mins”, “hours”, “days”, “weeks”
    last = ceiling (difftime(end, start,units=period))               
    samples <- list('id'=c(0:(last-1))) 
    lastdate = start
    start_dst = start$isdst
    dst = start_dst
    dst_offset_hour = 0
    hour.secs = 60*60
    day.secs = hour.secs*24
    for (i in 1:last) {        
        unixtime = as.numeric(start)+((i-1)*day.secs)
        new_date = as.POSIXlt(unixtime,origin="1970-01-01") 
        if (new_date$isdst != dst) {
            dst = new_date$isdst            
            if (dst == start_dst) dst_offset_hour = 0
            else if (start_dst == 0) dst_offset_hour = -hour.secs
            else if (start_dst == 1) dst_offset_hour = hour.secs
        }
        unixtime = unixtime + dst_offset_hour
        lastdate = as.POSIXlt(unixtime, origin="1970-01-01")
        samples$unixtime[i] = toString(unixtime)
        # samples$datedbg[i]=format(lastdate,"%H:%M %d-%m-%y")
        samples$date[i]=format(lastdate, "%b %Y")
    }
    completedata <- merge (data, samples, all=TRUE)
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
    new_data[is.na(new_data)] <- 0
    new_data <- new_data[order(new_data$id), ]    
    return (new_data)
}

# GLOBAL

mlsEvol <- function (rfield, period, startdate, enddate, identities_db, reports="") {    
    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders,
                    COUNT(DISTINCT(',rfield,')) AS repositories')
    tables = GetTablesOwnUniqueIds() 
    filters = GetFiltersOwnUniqueIds()
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)
    
    query <- new ("Query", sql = q)
    sent.senders.repos <- run(query)
        
    if (reports == "countries") {
        fields = 'COUNT(DISTINCT(c.id)) AS countries' 
        tables = GetTablesCountries(identities_db)   
        filters = GetFiltersCountries()         
        q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
                        startdate, enddate)
        query <- new ("Query", sql = q)
        countries <- run(query)        
    }
    if (reports == "companies") {
        fields = 'COUNT(DISTINCT(c.id)) AS companies' 
        tables = GetTablesCompanies(identities_db)
        filters = GetFiltersCompanies()         
        q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        companies <- run(query)
    }  
      
    mls <- sent.senders.repos
    if (reports == "countries") mls <- merge (mls, countries, all = TRUE)
    if (reports == "companies") mls <- merge (mls, companies, all = TRUE)
    return (mls)
}

mlsStatic <- function (rfield, startdate, enddate, reports="") {
    
    fields = "COUNT(*) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders,
              COUNT(DISTINCT(',rfield,')) AS repositories"
    tables = GetTablesOwnUniqueIds()
	filters = GetFiltersOwnUniqueIds()    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)
    sent.senders.first.last.repos <- run(query)
    
    q <- paste("SELECT mailing_list_url AS url FROM mailing_lists limit 1")
    query <- new ("Query", sql = q)
    repo_info <- run(query)
    
    if (reports == "countries") {
        fields = 'COUNT(DISTINCT(c.id)) AS countries' 
        tables = GetTablesCountries(identities_db)   
        filters = GetFiltersCountries()         
        q <- GetSQLGlobal('first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        countries <- run(query)        
    }
    if (reports == "companies") {
        fields = 'COUNT(DISTINCT(c.id)) AS companies' 
        tables = GetTablesCompanies(identities_db)   
        filters = GetFiltersCompanies()         
        q <- GetSQLGlobal('first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        companies <- run(query)
    }      
	
	agg_data = merge(sent.senders.first.last.repos, repo_info)
    if (reports == "country") 
        agg_data = merge(agg_data, countries)
    if (reports == "companies") 
        agg_data = merge(agg_data, companies)    
	return (agg_data)
}

# REPOSITORIES
reposField <- function() {
    rfield = 'mailing_list'
    query <- new ("Query", sql = "select distinct(mailing_list) from messages")
    mailing_lists <- run(query)
    if (is.na(mailing_lists$mailing_list)) {
        rfield = "mailing_list_url"
    }
    return (rfield);                
}

reposNames <- function (rfield, startdate, enddate) {    
    names = ""    
    if (rfield == "mailing_list_url") {
        query <- new ("Query",
                sql = paste("SELECT DISTINCT(mailing_list_url) FROM messages m 
                             WHERE m.first_date >= ",startdate," AND
                             m.first_date < ",enddate))   
        mailing_lists <- run(query)
        mailing_lists_files <- run(query)
        mailing_lists_files$mailing_list = gsub("/","_",mailing_lists$mailing_list)
        names = mailing_lists_files
    } else {
        query <- new ("Query", 
                sql = paste("SELECT DISTINCT(mailing_list) FROM messages m 
                             WHERE m.first_date >= ",startdate," AND
                             m.first_date < ",enddate))
        mailing_lists <- run(query)
        names = mailing_lists
    }    
    return (names)    
}

mlsEvolRepos <- function (rfield, repo, period, startdate, enddate) {    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders')
    tables = GetTablesOwnUniqueIds()
    filters = paste(GetFiltersOwnUniqueIds(),' AND
                    ',rfield,'=\'',repo,'\'',sep='') 
                        
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    sent.senders <- run(query)
        
    return(sent.senders)	
}

mlsStaticRepos <- function (rfield, repo, startdate, enddate) {
    fields = "COUNT(m.message_ID) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders"
    tables = GetTablesOwnUniqueIds()
	filters = paste(GetFiltersOwnUniqueIds(),' AND
                    ',rfield,'=\'',repo,'\'',sep='')    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
            startdate, enddate)

    query <- new ("Query", sql = q)
    data <- run(query)    
    return(data)
}

repoTopSenders <- function(repo, identities_db, startdate, enddate){
    q <- paste("SELECT up.identifier as senders,
                COUNT(m.message_id) as sent
                FROM ", GetTablesOwnUniqueIds(), ",",identities_db,".upeople up
                WHERE ", GetFiltersOwnUniqueIds(), " AND
                  pup.upeople_id = up.id AND
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate," AND
                  ",rfield,"='",repo,"'
                GROUP BY up.identifier
                ORDER BY sent desc
                LIMIT 10", sep="")    
    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


#
# COUNTRIES
#

countriesNames <- function (identities_db, startdate, enddate, filter=c()) {    
    countries_limit = 30
    
    filter_countries = ""
    for (country in filter){
        filter_countries <- paste(filter_countries, " c.name<>'",aff,"' AND ",sep="")
    }

    q <- paste("SELECT c.name as name, COUNT(m.message_ID) as sent
                FROM ", GetTablesCountries(identities_db), "
                WHERE ", GetFiltersCountries(), " AND
                  ", filter_countries, "
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate,"
                GROUP BY c.name
                ORDER BY COUNT((m.message_ID)) DESC LIMIT ", 
                countries_limit , sep="")
    
    query <- new ("Query", sql = q)
    data <- run(query)
    return(data$name)
}
    
mlsStaticCountries <- function (country, identities_db, startdate, enddate) {
    
    fields = "COUNT(m.message_ID) as sent,
            DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
            DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
            COUNT(DISTINCT(pup.upeople_id)) as senders"
    tables = GetTablesCountries(identities_db)
	filters = paste(GetFiltersCountries(),' AND 
                    c.name = \'', country, '\'',sep='')
    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    sent.first.last.senders <- run(query)    
    
    return (sent.first.last.senders)
}

mlsEvolCountries <- function (country, identities_db, period, startdate, enddate) {           		

    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders')
    tables = GetTablesCountries(identities_db)
    filters = paste(GetFiltersCountries(),' AND
                    c.name = \'', country, '\'',sep='') 

    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
                    startdate, enddate)                
            
    query <- new ("Query", sql = q)
    sent.senders <- run(query)
    
    return (sent.senders)
}

countryTopSenders <- function(country_name, identities_db, startdate, enddate){
    q <- paste("SELECT up.identifier as senders, 
                  COUNT(DISTINCT(m.message_id)) as sent 
                FROM ", GetTablesCountries(identities_db), 
                  ", ",identities_db,".upeople up
                WHERE ", GetFiltersCountries(), " AND
                  up.id = upc.upeople_id AND
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate," AND
                  c.name = '",country_name,"'
                GROUP BY up.identifier
                ORDER BY COUNT(DISTINCT(m.message_ID)) DESC LIMIT 10", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#
# COMPANIES
# 

companiesNames <- function (i_db, startdate, enddate, filter=c()) {    
    companies_limit = 30    
    filter_companies = ""

    for (company in filter){
        filter_companies <- paste(filter_companies, " c.name<>'",company,
                "' AND ",sep="")
    }
    
    q <- paste("SELECT c.name as name, COUNT(DISTINCT(m.message_ID)) as sent
                FROM ", GetTablesCompanies(i_db), "
                WHERE ", GetFiltersCompanies(), " AND
                  ", filter_companies, "
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate,"
                GROUP BY c.name
                ORDER BY COUNT(DISTINCT(m.message_ID)) DESC LIMIT ", 
            companies_limit , sep="")
    
    query <- new("Query", sql = q)    
    data <- run(query)
    return (data$name)    
}


mlsStaticCompanies <- function(company_name, i_db, startdate, enddate){
    
    fields = "COUNT(m.message_ID) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders"
    tables = GetTablesCompanies(i_db)
	filters = paste(GetFiltersCompanies(),' AND
                    c.name = \'',company_name,'\'',sep='')    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
                      startdate, enddate)
    query <- new ("Query", sql = q)
    sent.first.last.senders <- run(query)
    return (sent.first.last.senders)    
}

mlsEvolCompanies <- function(company_name, i_db, period, startdate, enddate) {
    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders')
    tables = GetTablesCompanies(i_db)
	filters = paste(GetFiltersCompanies(),' AND
                    c.name = \'',company_name,'\'',sep='')
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)                    
    query <- new ("Query", sql = q)
    sent.senders <- run(query)    
    return (sent.senders)   
}

companyTopSenders <- function(company_name, identities_db, startdate, enddate){
    q <- paste("SELECT up.identifier as senders, 
                  COUNT(DISTINCT(m.message_id)) as sent 
                FROM ", GetTablesCompanies(identities_db), 
                  ", ",identities_db,".upeople up
                WHERE ", GetFiltersCompanies(), " AND
                  up.id = upc.upeople_id AND
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate," AND
                  c.name = '",company_name,"'
                GROUP BY up.identifier
                ORDER BY COUNT(DISTINCT(m.message_ID)) DESC LIMIT 10", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


# 
# TOPS
#
top_senders <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {

    clean_people = ""
    for (person in filter){
        clean_people <- paste(clean_people, " up.identifier<>'",person,"' and ",sep="")
    }
        
    date_limit = ""
    if (days != 0 ) {
    	query <- new ("Query",
                sql = "SELECT @maxdate:=max(first_date) from messages limit 1")        
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate,first_date)<",days)
    }    
    
    q <- paste("SELECT up.identifier as senders,
                COUNT(m.message_id) as sent
                FROM ", GetTablesOwnUniqueIds(), ",",identities_db,".upeople up
    			WHERE ", GetFiltersOwnUniqueIds(), " AND
                  pup.upeople_id = up.id AND
                  ", clean_people, "
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate,
                  date_limit, "
                GROUP BY up.identifier
                ORDER BY sent desc
                LIMIT 10;", sep="")    
    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

# 
# Util
#

lastActivity <- function(days) {
    #commits
    q <- paste("select count(distinct(message_ID)) as sent_",days,"
                from messages
                where first_date >= (
                  select (max(first_date) - INTERVAL ",days," day)
                  from messages)", sep="");
    query <- new("Query", sql = q)
    data1 = run(query)
    
    q <- paste("select count(distinct(pup.upeople_id)) as senders_",days,"
                from messages m,
                  people_upeople pup,
                  messages_people mp
                where pup.people_id = mp.email_address  and
                  m.message_ID = mp.message_id and 
                  m.first_date >= (select (max(first_date) - INTERVAL ",days," day) 
                                   from messages)", 
         sep="");
    query <- new("Query", sql = q)
    data2 = run(query)
    
    agg_data = merge(data1, data2)
    
    return(agg_data)    
}

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
             pup.upeople_id = up.id AND 
             mp.type_of_recipient=\'From\'') 
}

GetTablesCountries <- function(i_db) {
    return (paste(GetTablesOwnUniqueIds(),' 
                  ',i_db,'.upeople up,
                  ',i_db,'.countries c,
                  ',i_db,'.upeople_countries upc',sep=''))
}

GetFiltersCountries <- function() {
    return (paste(GetFiltersOwnUniqueIds(),' AND
                  up.id  = upc.upeople_id and
                  upc.country_id = c.id'))
}

GetTablesCompanies <- function(i_db) {
    return (paste(GetTablesOwnUniqueIds(),' 
                  ',i_db,'.upeople up,
                  ',i_db,'.companies c,
                  ',i_db,'.upeople_companies upc',sep=''))
}

GetFiltersCompanies <- function() {
    return (paste(GetFiltersOwnUniqueIds(),' AND
                  up.id  = upc.upeople_id AND
                  upc.company_id = c.id AND
                  m.first_date >= upc.init AND
                  m.first_date < upc.end'))
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
        print(q)
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
        q <- GetSQLGLobal(period,'first_date', fields, tables, filters, 
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
mlsEvolList <- function (listname, period, startdate, enddate) {
    
    rfield = "mailing_list"
    if (length(i <- grep("http",listname))) {
        rfield = "mailing_list_url"
    }          
    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders')
    tables = GetTablesOwnUniqueIds()
    filters = paste(GetFiltersOwnUniqueIds(),' AND
                    ',rfield,'=',listname,sep='') 
                        
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    sent.senders <- run(query)
        
    return(sent.senders)	
}

mlsStaticList <- function (rfield, listname, period, startdate, enddate) {
	
    ## Get some general stats from the database
    ##
    
    fields = "COUNT(*) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders"
    tables = GetTablesOwnUniqueIds()
	filters = paste(GetFiltersOwnUniqueIds(),' AND
                    ',rfield,'=',listname,sep='')    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
            startdate, enddate)
    
    query <- new ("Query", sql = q)
    data <- run(query)
    
    return(data)
}

# 
# Util
#

last_activity_mls <- function(days) {
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
                      m.first_date >= (select (max(first_date) - INTERVAL ",days," day) from messages)", sep="");
    query <- new("Query", sql = q)
    data2 = run(query)

    agg_data = merge(data1, data2)

    return(agg_data)    
}

#
# COUNTRIES
#

countries_names <- function (identities_db, startdate, enddate) {
    # Countries
    country_limit = 30
    q <- paste("SELECT count(m.message_id) as sent, c.name as country 
                FROM messages m, messages_people m_p, people_upeople pup,
                  ",identities_db,".upeople up,
                  ",identities_db,".countries c,
                  ",identities_db,".upeople_countries upc
                 WHERE m_p.message_id=m.message_ID AND
                   m_p.email_address = pup.people_id and
                   pup.upeople_id = up.id and
                   up.id  = upc.upeople_id and
                   upc.country_id = c.id and
                   m.first_date >= ", startdate, " and
                   m.first_date < ", enddate, "
                 GROUP BY c.name
                 ORDER BY sent desc LIMIT ", country_limit)
    query <- new ("Query", sql = q)
    data <- run(query)
    countries<-data$country    
}
    


mlsEvolCountries <- function (identities_db, country, period, startdate, enddate) {           		
    # Sent and sender time series evol	
	## q <- paste("SELECT year(first_date) * 12 + month(first_date) AS id,
        ##           year(first_date) AS year,
        ##           month(first_date) AS month,
        ##           DATE_FORMAT (first_date, '%b %Y') as date,
        ##           count(m.message_ID) AS sent,
        ##           count(distinct(p.email_address)) AS senders
        ##         FROM messages m
        ##         JOIN messages_people mp ON mp.message_ID=m.message_id
        ##         JOIN people p ON mp.email_address = p.email_address
        ##         WHERE country='",country,"'
        ##         GROUP BY year,month
        ##         ORDER BY year,month",sep = '')

    q <- paste("SELECT ((to_days(first_date) - to_days(",startdate,")) div ",period,") as id,
                count(m.message_ID) AS sent,
				COUNT(DISTINCT(m_p.email_address)) as senders
                FROM  messages m, messages_people m_p, people_upeople pup,
                  ",identities_db,".upeople up,
				  ",identities_db,".countries c,
				  ",identities_db,".upeople_countries upc
                 WHERE m_p.message_id=m.message_ID AND 
                   m_p.email_address = pup.people_id and
                   pup.upeople_id = up.id and
                   up.id  = upc.upeople_id and
                   upc.country_id = c.id and
                   m.first_date >= ", startdate, " and
                   m.first_date < ", enddate, " and
                   c.name = '", country, "'				
                GROUP BY ((to_days(first_date) - to_days(",startdate,")) div ",period,")", sep="")

	query <- new ("Query", sql = q)
	evol_monthly <- run(query)
    return (evol_monthly)
}

mlsStaticCountries <- function (identities_db, country, startdate, enddate) {
    ## Get some general stats from mls
    q <- paste ("SELECT count(m.message_ID) as sent,
                   DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
                   DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date,
                   COUNT(DISTINCT(m_p.email_address)) as senders
                FROM  messages m, messages_people m_p, people_upeople pup,
                  ",identities_db,".upeople up,
				  ",identities_db,".countries c,
				  ",identities_db,".upeople_countries upc
                 WHERE m_p.message_id=m.message_ID AND 
                   m_p.email_address = pup.people_id and
                   pup.upeople_id = up.id and
                   up.id  = upc.upeople_id and
                   upc.country_id = c.id and
                   m.first_date >= ", startdate, " and
                   m.first_date < ", enddate, " and
                   c.name = '", country, "'", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


top_senders <- function(days = 0, startdate, enddate, identites_db) {
    
    date_limit = ""
    if (days != 0 ) {
    	query <- new ("Query",
                sql = "SELECT @maxdate:=max(first_date) from messages limit 1")        
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate,first_date)<",days)
    }
    q <- paste("SELECT u.identifier as senders,
                  count(m.message_id) as sent
               FROM messages m, messages_people m_p, 
                    people_upeople pup,
                    ",identities_db,".upeople u
               WHERE m_p.message_id=m.message_ID AND 
                     m_p.email_address = pup.people_id and
                     pup.upeople_id = u.id and
                     m.first_date >= ", startdate, " and
                     m.first_date < ", enddate, 
                     date_limit, " 
               GROUP BY u.identifier
               ORDER BY sent desc
               LIMIT 10;", sep="")    
	print (q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

top_senders_wo_affs <- function(list_affs, i_db, startdate, enddate){

        affiliations = ""
        for (aff in list_affs){
            affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
        }

    q <- paste("SELECT u.identifier as senders, 
                 count(distinct(m.message_id)) as sent
          FROM messages m,
               messages_people mp,
               people_upeople pup,
               ",i_db,".upeople u,
               ",i_db,".upeople_companies upc,
               ",i_db,".companies c
          where m.message_ID = mp.message_id and
                mp.email_address = pup.people_id and
                pup.upeople_id = upc.upeople_id and
                pup.upeople_id = u.id and
                ",affiliations,"
                upc.company_id = c.id and
                m.first_date >= ",startdate," and
                m.first_date < ",enddate,"
          GROUP by mp.email_address 
          ORDER BY sent DESC LIMIT 10;", sep="")
   # print(q)
   query <- new ("Query", sql = q)
   data <- run(query)
   return (data)


}


#Companies information

companies_names_wo_affs <- function(list_affs, i_db, startdate, enddate) {

    affiliations = ""
    for (aff in list_affs){
        affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
    }


    q <- paste("select c.name as name,
                       count(distinct(m.message_ID)) as sent
                from messages m,
                     messages_people mp,
                     people_upeople pup,
                     ",i_db,".upeople_companies upc,
                     ",i_db,".companies c
                where m.message_ID = mp.message_id and
                      mp.email_address  = pup.people_id and
                      pup.upeople_id = upc.upeople_id and
                      upc.company_id = c.id and
                      m.first_date >= upc.init and
                      m.first_date < upc.end and 
                      ", affiliations, "
                      m.first_date >= ",startdate," and
                      m.first_date < ",enddate,"
                group by c.name
                order by count(distinct(m.message_ID)) desc;" , sep="")
    query <- new("Query", sql = q)
   
    data <- run(query)
    return (data)
}

companies_names <- function (i_db, startdate, enddate){

    companies_limit = 30

    q <- paste("select c.name as name,
                       count(distinct(m.message_ID)) as sent
                from messages m,
                     messages_people mp,
                     people_upeople pup,
                     ",i_db,".upeople_companies upc,
                     ",i_db,".companies c
                where m.message_ID = mp.message_id and
                      mp.email_address  = pup.people_id and
                      pup.upeople_id = upc.upeople_id and
                      upc.company_id = c.id and
                      m.first_date >= ",startdate," and
                      m.first_date < ",enddate,"
                group by c.name
                order by count(distinct(m.message_ID)) desc LIMIT ", companies_limit , sep="")
                # order by count(distinct(m.message_ID)) desc", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)

}


company_posts_posters <- function(company_name, i_db, period, startdate, enddate){
    # company_name: name of the company in the database
    # i_db: database where identities and companies info is found
    # period: granularity of weeks or months
    # startdate: initial date of analysis
    # enddate: final date of analysis

    q <- paste("select ((to_days(m.first_date) - to_days(",startdate,")) div ",period,") as id,
                       count(m.message_ID) AS sent,
                                 count(distinct(mp.email_address)) AS senders
                          FROM messages m,
                               messages_people mp,
                               people_upeople pup,
                               ",i_db,".upeople_companies upc,
                               ",i_db,".companies c
                          where m.message_ID = mp.message_id and
                                mp.email_address = pup.people_id and
                                pup.upeople_id = upc.upeople_id and
                                upc.company_id = c.id and
                                m.first_date >= upc.init and
                                m.first_date < upc.end and 
                                c.name = ",company_name," and
                                m.first_date>=",startdate," and m.first_date<",enddate,"
                group by ((to_days(m.first_date) - to_days(",startdate,")) div ",period,")", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)

}


company_top_senders <- function(company_name, i_db, period, startdate, enddate){

    q <- paste("select p.name as senders, 
                       count(distinct(m.message_id)) as sent 
                from messages m,
                     messages_people mp,
                     people p,
                     people_upeople pup,
                     ",i_db,".upeople_companies upc,
                     ",i_db,".companies c
                where m.message_ID = mp.message_id and
                      mp.email_address = pup.people_id and
                      mp.email_address = p.email_address and
                      pup.upeople_id = upc.upeople_id and
                      upc.company_id = c.id and
                      m.first_date >= upc.init and
                      m.first_date < upc.end and
                      c.name = ",company_name," and
                      m.first_date >= ",startdate," and
                      m.first_date < ",enddate,"
                group by p.name
                order by count(distinct(m.message_id)) desc 
                limit 10", sep="")

    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


company_static_info <- function(company_name, i_db, startdate, enddate){

    #posts
    q <- paste("select count(distinct(mp.email_address)) as senders,
                       count(distinct(m.message_id)) as sent,
                       count(distinct(m.mailing_list_url)) as repositories
                from messages m,
                     messages_people mp,
                     people_upeople pup,
                     ",i_db,".upeople_companies upc,
                     ",i_db,".companies c
                where m.message_ID = mp.message_id and
                      mp.email_address = pup.people_id and
                      pup.upeople_id = upc.upeople_id and
                      upc.company_id = c.id and
                      c.name = ",company_name," and
                      m.first_date >= ",startdate," and
                      m.first_date < ",enddate,";", sep="")
 
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)

}
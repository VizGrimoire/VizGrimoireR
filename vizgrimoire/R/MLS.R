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


GetTablesOwnUniqueIdsMLS <- function() {
    return ('messages m, messages_people mp, people_upeople pup')
}

# Using senders only here!
GetFiltersOwnUniqueIdsMLS <- function () {
    return ('m.message_ID = mp.message_id AND 
             mp.email_address = pup.people_id AND 
             mp.type_of_recipient=\'From\'') 
}

GetTablesCountries <- function(i_db) {
    return (paste(GetTablesOwnUniqueIdsMLS(),', 
                  ',i_db,'.countries c,
                  ',i_db,'.upeople_countries upc',sep=''))
}

GetFiltersCountries <- function() {
    return (paste(GetFiltersOwnUniqueIdsMLS(),' AND
                  pup.upeople_id = upc.upeople_id AND
                  upc.country_id = c.id'))
}

GetTablesCompanies <- function(i_db) {
    return (paste(GetTablesOwnUniqueIdsMLS(),',
                  ',i_db,'.companies c,
                  ',i_db,'.upeople_companies upc',sep=''))
}

GetFiltersCompanies <- function() {
    return (paste(GetFiltersOwnUniqueIdsMLS(),' AND
                  pup.upeople_id = upc.upeople_id AND
                  upc.company_id = c.id AND
                  m.first_date >= upc.init AND
                  m.first_date < upc.end'))
}


# GLOBAL

GetEvolMLS <- function (rfield, period, startdate, enddate, identities_db, reports=c('')) {    
    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders,
                    COUNT(DISTINCT(',rfield,')) AS repositories,
                    COUNT(DISTINCT(m.is_response_of)) AS threads')
    tables = GetTablesOwnUniqueIdsMLS() 
    filters = GetFiltersOwnUniqueIdsMLS()
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)
    
    print(q)
    
    query <- new ("Query", sql = q)
    sent.senders.repos.threads <- run(query)    
        
    if ("countries" %in% reports) {
        fields = 'COUNT(DISTINCT(c.id)) AS countries' 
        tables = GetTablesCountries(identities_db)   
        filters = GetFiltersCountries()         
        q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
                        startdate, enddate)
        query <- new ("Query", sql = q)
        countries <- run(query)        
    }
    if ("companies" %in% reports) {
        fields = 'COUNT(DISTINCT(c.id)) AS companies' 
        tables = GetTablesCompanies(identities_db)
        filters = GetFiltersCompanies()         
        q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        companies <- run(query)
    }  
      
    mls <- sent.senders.repos.threads
    if ("countries" %in% reports) mls <- merge (mls, countries, all = TRUE)
    if ("companies" %in% reports) mls <- merge (mls, companies, all = TRUE)
    return (mls)
}

GetStaticMLS <- function (rfield, startdate, enddate, reports=c('')) {
    
    fields = "COUNT(*) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders,
              COUNT(DISTINCT(',rfield,')) AS repositories,
              COUNT(DISTINCT(m.is_response_of)) AS threads"
    tables = GetTablesOwnUniqueIdsMLS()
	filters = GetFiltersOwnUniqueIdsMLS()    
    q <- GetSQLGlobal('first_date', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)
    sent.senders.first.last.repos <- run(query)
    
    # Specific SQL queries for special metrics
    q <- paste("SELECT mailing_list_url AS url FROM mailing_lists limit 1")
    query <- new ("Query", sql = q)
    repo_info <- run(query)
    
    q <- paste("SELECT AVG(thread_size) AS thread_size_avg FROM 
                (SELECT COUNT(*) as thread_size, is_response_of FROM messages 
                 WHERE is_response_of is not NULL GROUP BY is_response_of) dt")
    query <- new ("Query", sql = q)
    thread_size <- run(query)
    
    q <- paste("SELECT AVG(persons) AS thread_persons_avg FROM
                (SELECT COUNT(DISTINCT(email_address)) AS persons  
                 FROM messages m, messages_people mp  
                 WHERE m.message_ID = mp.message_ID  
                 AND m.is_response_of IS NOT NULL  
                 GROUP BY m.is_response_of) dt")
    query <- new ("Query", sql = q)
    thread_persons <- run(query)
    
    q <- paste("SELECT COUNT(message_ID) as messages_no_response 
                FROM messages WHERE message_ID NOT IN 
                (SELECT DISTINCT(is_response_of) FROM messages 
                 WHERE is_response_of IS NOT NULL)")
    query <- new ("Query", sql = q)
    messages_no_response <- run(query)

 
    if ("countries"  %in% reports) {
        fields = 'COUNT(DISTINCT(c.id)) AS countries' 
        tables = GetTablesCountries(identities_db)   
        filters = GetFiltersCountries()         
        q <- GetSQLGlobal('first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        countries <- run(query)        
    }
    if ("companies" %in% reports) {
        fields = 'COUNT(DISTINCT(c.id)) AS companies' 
        tables = GetTablesCompanies(identities_db)   
        filters = GetFiltersCompanies()         
        q <- GetSQLGlobal('first_date', fields, tables, filters, 
                startdate, enddate)
        query <- new ("Query", sql = q)
        companies <- run(query)
    }      
	
	agg_data = merge(sent.senders.first.last.repos, repo_info)
    agg_data = merge(agg_data, thread_size)
    agg_data = merge(agg_data, thread_persons)
    agg_data = merge(agg_data, messages_no_response)
    if ("countries"  %in% reports) agg_data = merge(agg_data, countries)
    if ("companies"  %in% reports) agg_data = merge(agg_data, companies)
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

GetEvolReposMLS <- function (rfield, repo, period, startdate, enddate) {    
    fields = paste('COUNT(m.message_ID) AS sent, 
                    COUNT(DISTINCT(pup.upeople_id)) as senders')
    tables = GetTablesOwnUniqueIdsMLS()
    filters = paste(GetFiltersOwnUniqueIdsMLS(),' AND
                    ',rfield,'=\'',repo,'\'',sep='') 
                        
    q <- GetSQLPeriod(period,'first_date', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    sent.senders <- run(query)
        
    return(sent.senders)	
}

GetStaticReposMLS <- function (rfield, repo, startdate, enddate) {
    fields = "COUNT(m.message_ID) as sent,
              DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date,
              COUNT(DISTINCT(pup.upeople_id)) as senders"
    tables = GetTablesOwnUniqueIdsMLS()
	filters = paste(GetFiltersOwnUniqueIdsMLS(),' AND
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
                FROM ", GetTablesOwnUniqueIdsMLS(), ",",identities_db,".upeople up
                WHERE ", GetFiltersOwnUniqueIdsMLS(), " AND
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
    
GetStaticCountriesMLS <- function (country, identities_db, startdate, enddate) {
    
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

GetEvolCountriesMLS <- function (country, identities_db, period, startdate, enddate) {           		

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


GetStaticCompaniesMLS <- function(company_name, i_db, startdate, enddate){
    
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

GetEvolCompaniesMLS <- function(company_name, i_db, period, startdate, enddate) {
    
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
# People
#

# TODO: It is the same than SCM because unique identites
GetListPeopleMLS <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id"
    tables = GetTablesOwnUniqueIdsMLS()
    filters = GetFiltersOwnUniqueIdsMLS()
    q = GetSQLGlobal('first_date',fields,tables, filters, startdate, enddate)        
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)        
}

GetQueryPeopleMLS <- function(developer_id, period, startdate, enddate, evol) {    
    fields = "COUNT(m.message_ID) AS sent"
    tables = GetTablesOwnUniqueIdsMLS()
    filters = paste(GetFiltersOwnUniqueIdsMLS(), "AND pup.upeople_id = ", developer_id)
    
    if (evol) {
        q = GetSQLPeriod(period,'first_date', fields, tables, filters, 
                startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(first_date),'%Y-%m-%d') as first_date,
                DATE_FORMAT (max(first_date),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('first_date', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)
}


GetEvolPeopleMLS <- function(developer_id, period, startdate, enddate) {
    q <- GetQueryPeopleMLS(developer_id, period, startdate, enddate, TRUE)    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetStaticPeopleMLS <- function(developer_id, startdate, enddate) {
    q <- GetQueryPeopleMLS(developer_id, period, startdate, enddate, FALSE)      
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}


# 
# TOPS
#
top_senders <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {

    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " c.name<>'", aff ,"' and ", sep="")
    }
        
    date_limit = ""
    if (days != 0 ) {
    	query <- new ("Query",
                sql = "SELECT @maxdate:=max(first_date) from messages limit 1")        
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate,first_date)<",days)
    }    
    
    q <- paste("SELECT up.id as id, up.identifier as senders,
                COUNT(distinct(m.message_id)) as sent
                FROM ", GetTablesCompanies(identities_db), 
                     ",",identities_db,".upeople up
                WHERE ", GetFiltersCompanies(), " AND
                  pup.upeople_id = up.id AND
                  ", affiliations , "
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

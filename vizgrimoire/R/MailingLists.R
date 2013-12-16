## Copyright (C) 2013 Bitergia
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
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>


##############
# Specific FROM and WHERE clauses per type of report
##############

GetMLSSQLRepositoriesFrom <- function(){
    # tables necessary for repositories
    #return (" messages m ") 
    return ("")
}

GetMLSSQLRepositoriesWhere <- function(repository){
    # fields necessary to match info among tables
    return (paste(" m.mailing_list_url = '",repository,"' "))
}


GetMLSSQLCompaniesFrom <- function(i_db){
    # fields necessary for the companies analysis
    
    return(paste(" , messages_people mp, 
                   people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetMLSSQLCompaniesWhere <- function(){
    # filters for the companies analysis
    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   m.first_date >= upc.init and
                   m.first_date < upc.end ", sep=""))
}

GetMLSSQLCountriesFrom <- function(i_db){
    # fields necessary for the countries analysis
    return(paste(" , messages_people mp, 
                   people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_countries upc ", sep=""))
}

GetMLSSQLCountriesWhere <- function(){
    # filters necessary for the countries analysis

    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   m.first_date >= upc.init and
                   m.first_date < upc.end ", sep=""))

}

# Using senders only here!
GetMLSFiltersOwnUniqueIdsMLS <- function () {
    return ('m.message_ID = mp.message_id AND
             mp.email_address = pup.people_id AND
             mp.type_of_recipient=\'From\'')
}


##############
# Generic functions to check evolutionary or aggregated info
# and for the execution of the final query
##############

BuildQuery <- function(period, startdate, enddate, date_field, fields, tables, filters, evolutionary){
    # Select the way to evolutionary or aggregated dataset

    q = ""

    if (evolutionary) {
         q <- GetMLSSQLPeriod(period, date_field, fields, tables, filters,
            startdate, enddate)
    } else {
         q <- GetMLSSQLGlobal(date_field, fields, tables, filters,
                           startdate, enddate)
    }

    return(q)
}


ExecuteQuery <- function(q){
    # This function creates a new object Query and
    # returns the result

    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########


GetMLSSQLReportFrom <- function(identities_db, type_analysis){
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetMLSSQLRepositoriesFrom()),
                ifelse (analysis == 'company', paste(from, GetMLSSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', paste(from, GetMLSSQLCountriesFrom(identities_db)),
                NA)))
    }
    return (from)
}


GetMLSSQLReportWhere <- function(type_analysis){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)){
        where <- ifelse (analysis == 'repository', paste(where, GetMLSSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(where, GetMLSSQLCompaniesWhere()),
                ifelse (analysis == 'country', paste(where, GetMLSSQLCountriesWhere(value)),
                NA)))
    }
    return (where)
}

#########
# Other generic functions
#########

reposField <- function() {
    # Depending on the mailing list, the field to be
    # used is mailing_list or mailing_list_url
    rfield = 'mailing_list'
    query <- new ("Query", sql = "select count(distinct(mailing_list)) from messages")
    mailing_lists <- run(query)
    if (mailing_lists == 0) {
        rfield = "mailing_list_url"
    }
    return (rfield);
}


GetMLSFiltersResponse <- function() {
    filters = GetMLSFiltersOwnUniqueIdsMLS()
    filters_response = paste(filters, " AND m.is_response_of IS NOT NULL")
}


##########
# Meta functions that aggregate all evolutionary or static data in one call
##########


GetMLSInfo <- function(period, startdate, enddate, identities_db, rfield, type_analysis, evolutionary){

    data = data.frame()

    if (evolutionary == TRUE){
        sent = EvolEmailsSent(period, startdate, enddate, identities_db)
        senders = EvolMLSSenders(period, startdate, enddate, identities_db)
        repositories = EvolMLSRepositories(rfield, period, startdate, enddate, identities_db)
        threads = EvolThreads(period, startdate, enddate, identities_db)
        sent_response = EvolMLSResponses(period, startdate, enddate, identities_db)
        senders_response = EvolMLSSendersResponse(period, startdate, enddate, identities_db)
        senders_init = EvolMLSSendersInit(period, startdate, enddate, identities_db)
        #countries = 
        #companies =

        data = merge(sent, senders, all=TRUE)
        data = merge(data, repositories, all=TRUE)
        data = merge(data, threads, all=TRUE)
        data = merge(data, sent_response, all=TRUE)
        data = merge(data, senders_init, all=TRUE)

    } else {
        sent = AggEmailsSent(period, startdate, enddate, identities_db)
        senders = AggMLSSenders(period, startdate, enddate, identities_db)
        repositories = AggMLSRepositories(rfield, period, startdate, enddate, identities_db)
        threads = AggThreads(period, startdate, enddate, identities_db)
        sent_response = AggMLSResponses(period, startdate, enddate, identities_db)
        senders_response = AggMLSSendersResponse(period, startdate, enddate, identities_db)
        senders_init = AggMLSSendersInit(period, startdate, enddate, identities_db)

        data = merge(sent, senders, all=TRUE)
        data = merge(data, repositories, all=TRUE)
        data = merge(data, threads, all=TRUE)
        data = merge(data, sent_response, all=TRUE)
        data = merge(data, senders_init, all=TRUE)
    }

    return (data)
}


EvolMLSInfo <- function(period, startdate, enddate, identities_db, rfield, type_analysis = list(NA, NA)){
    #Evolutionary info all merged in a dataframe
    return(GetMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis, TRUE))
}


StaticMLSInfo <- function(period, startdate, enddate, identities_db, rfield, type_analysis = list(NA, NA)){
    #Agg info all merged in a dataframe
    return(GetMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis, FALSE))
}



#########
#Functions to obtain info per type of basic piece of data
#########

# All of the EvolXXX or StaticXXX contains the same parameters:
#    period:
#    startdate:
#    enddate:
#    identities_db: MySQL database name
#    type_analysis: tuple with two values: typeof and value
#                   typeof = 'companies', 'countries', 'repositories' or ''
#                   value = any value that corresponds with the type of analysis


# Emails Sent
GetEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts emails sent

    fields = " count(distinct(m.message_ID)) as sent "
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = GetMLSSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)

    return(ExecuteQuery(q))
}

EvolEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evolution of emails sent
    return(GetEmailsSent(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails sent
    return(GetEmailsSent(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


# People sending emails
GetMLSSenders <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #Generic function that counts people sending messages
    
    fields = " count(distinct(pup.upeople_id)) as senders "
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    print(tables)
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        filters = GetMLSSQLReportWhere(type_analysis)
    }

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)
    return(ExecuteQuery(q))
}

EvolMLSSenders <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evolution of people sending emails
    return(GetMLSSenders(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSenders <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Agg of people sending emails
    return(GetMLSSenders(period, startdate, enddate, identities_db, type_analysis , FALSE))
}


# People answering in a thread

GetMLSSendersResponse <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #Generic function that counts people sending messages

    fields = " count(distinct(pup.upeople_id)) as senders_response "
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    print(tables)
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        filters = GetMLSSQLReportWhere(type_analysis)
    }
    filters = paste(filters, " and m.is_response_of is not null ", sep="")


    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)
    return(ExecuteQuery(q))
}

EvolMLSSendersResponse <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evolution of people sending emails
    return(GetMLSSendersResponse(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSendersResponse <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Agg of people sending emails
    return(GetMLSSendersResponse(period, startdate, enddate, identities_db, type_analysis , FALSE))
}


# People starting threads

GetMLSSendersInit <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #Generic function that counts people sending messages

    fields = " count(distinct(pup.upeople_id)) as senders_init "
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    print(tables)
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        filters = GetMLSSQLReportWhere(type_analysis)
    }
    filters = paste(filters, " and m.is_response_of is null ", sep="")


    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)
    return(ExecuteQuery(q))
}

EvolMLSSendersInit <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evolution of people sending emails
    return(GetMLSSendersInit(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSendersInit <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Agg of people sending emails
    return(GetMLSSendersInit(period, startdate, enddate, identities_db, type_analysis , FALSE))
}





# Threads
GetThreads <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts threads

    fields = " count(distinct(m.is_response_of)) as threads"
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))    
    filters = GetMLSSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolThreads <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails sent
    return(GetThreads(period, startdate, enddate, identities_db, type_analysis, TRUE))
}
 

AggThreads <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails sent
    return(GetThreads(period, startdate, enddate, identities_db, type_analysis, FALSE))
}
 
# Repositories
GetMLSRepositories <- function(rfield, period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts threads

    fields = " COUNT(DISTINCT(',rfield,')) AS repositories  "
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = GetMLSSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolMLSRepositories <- function(rfield, period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails sent
    return(GetMLSRepositories(rfield, period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSRepositories <- function(rfield, period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails sent
    return(GetMLSRepositories(rfield, period, startdate, enddate, identities_db, type_analysis, FALSE))
}


# Messages replying a thread
GetMLSResponses <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts replies

    fields = " count(distinct(m.message_ID)) as sent_response"
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = paste(GetMLSSQLReportWhere(type_analysis), " m.is_response_of is not null ", sep="")

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)
    return(ExecuteQuery(q))
}

EvolMLSResponses <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evol number of replies
    return(GetMLSResponses(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSResponses <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails replied
    return(GetMLSResponses(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

# Messages starting threads
GetMLSInit <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts replies

    fields = " count(distinct(m.message_ID)) as sent_init"
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = paste(GetMLSSQLReportWhere(type_analysis), " m.is_response_of is null ", sep="")

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)
    return(ExecuteQuery(q))
}

EvolMLSInit <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Evol number of messages starting a thread
    return(GetMLSInit(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSInit <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # Aggregated number of emails starting a thread
    return(GetMLSInit(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



####################
# Lists of repositories, companies, countries, etc
# Functions to obtain list of names (of repositories) per type of analysis
####################


# WARNING: Functions directly copied from old MLS.R

reposNames <- function (rfield, startdate, enddate) {
    names = ""
    if (rfield == "mailing_list_url") {
        q = paste("SELECT ml.mailing_list_url, COUNT(message_ID) AS total
                   FROM messages m, mailing_lists ml
                   WHERE m.mailing_list_url = ml.mailing_list_url AND
                   m.first_date >= ",startdate," AND
                   m.first_date < ",enddate,"
                   GROUP BY ml.mailing_list_url ORDER by total desc")
        query <- new ("Query", sql = q)
        print(q)
        mailing_lists <- run(query)
        mailing_lists_files <- run(query)
        names = mailing_lists_files
    } else {
        # TODO: not ordered yet by total messages
        q = paste("SELECT DISTINCT(mailing_list) FROM messages m
                        WHERE m.first_date >= ",startdate," AND
                        m.first_date < ",enddate)
        query <- new ("Query", sql = q)
        print(q)
        mailing_lists <- run(query)
        names = mailing_lists
    }
    return (names)
}


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
    query <- new ("Query", sql = q)
    data <- run(query)
    return(data$name)
}


########################
# People functions as in the old version, still to be refactored!
########################

GetListPeopleMLS <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id, count(m.message_ID) total"
    tables = GetTablesOwnUniqueIdsMLS()
    filters = GetFiltersOwnUniqueIdsMLS()
    filters = paste(filters,"GROUP BY id ORDER BY total desc")
    q = GetSQLGlobal('first_date',fields,tables, filters, startdate, enddate)
    print(q)
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



#########################
# Top activity developers
#########################


top_senders <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {

    limit = 30
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
                LIMIT ",limit, ";", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
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




#######################
# Functions to analyze last activity
#######################

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



#####################
# MICRO STUDIES
#####################

StaticNumSent <- function(startdate, enddate){
   fields = paste(" COUNT(*) as sent ")
    tables = GetTablesOwnUniqueIdsMLS()
    filters = GetFiltersOwnUniqueIdsMLS()
    q <- GetSQLGlobal('first_date', fields, tables, filters,
            startdate, enddate)
    print(q)
    query <- new ("Query", sql = q)
    sent <- run(query)
    return(sent)
}

StaticNumSenders <- function(startdate, enddate){
fields = paste(" COUNT(DISTINCT(pup.upeople_id)) as senders ")
    tables = GetTablesOwnUniqueIdsMLS()
    filters = GetFiltersOwnUniqueIdsMLS()
    q <- GetSQLGlobal('first_date', fields, tables, filters,
            startdate, enddate)
    print(q)
    query <- new ("Query", sql = q)
    senders <- run(query)
    return(senders)
}

GetDiffSentDays <- function(period, init_date, days){
    # This function provides the percentage in activity between two periods
    chardates = GetDates(init_date, days)
    lastsent = StaticNumSent(chardates[2], chardates[1])
    lastsent = as.numeric(lastsent[1])
    prevsent = StaticNumSent(chardates[3], chardates[2])
    prevsent = as.numeric(prevsent[1])
    diffsentdays = data.frame(diff_netsent = numeric(1), percentage_sent = numeric(1))

    diffsentdays$diff_netsent = lastsent - prevsent
    diffsentdays$percentage_sent = GetPercentageDiff(prevsent, lastsent)

    colnames(diffsentdays) <- c(paste("diff_netsent","_",days, sep=""), paste("percentage_sent","_",days, sep=""))

    return (diffsentdays)
}


GetDiffSendersDays <- function(period, init_date, days){
    # This function provides the percentage in activity between two periods
    chardates = GetDates(init_date, days)
    lastsenders = StaticNumSenders(chardates[2], chardates[1])
    lastsenders = as.numeric(lastsenders[1])
    prevsenders = StaticNumSenders(chardates[3], chardates[2])
    prevsenders = as.numeric(prevsenders[1])
    diffsendersdays = data.frame(diff_netsenders = numeric(1), percentage_senders = numeric(1))

    diffsendersdays$diff_netsenders = lastsenders - prevsenders
    diffsendersdays$percentage_senders = GetPercentageDiff(prevsenders, lastsenders)

    colnames(diffsendersdays) <- c(paste("diff_netsenders","_",days, sep=""), paste("percentage_senders","_",days, sep=""))

    return (diffsendersdays)

}


GetSentSummaryCompanies <- function(period, startdate, enddate, identities_db, num_companies){
    # This function provides the top <num_companies> sending messages to the mailing
    # lists

    companies  <- companiesNames(identities_db, startdate, enddate, c("-Bot", "-Individual", "-Unknown"))

    first = TRUE
    first_companies = data.frame()
    count = 1
    for (company in companies){

        sent = EvolMessagesSentCompanies(company, identities_db, period, startdate, enddate)
        sent <- completePeriodIds(sent, conf$granularity, conf)
        sent <- sent[order(sent$id), ]
        sent[is.na(sent)] <- 0

        if (count <= num_companies -1){
            #Case of companies with entity in the dataset
            if (first){
                first = FALSE
                first_companies = sent
            }
            first_companies = merge(first_companies, sent, all=TRUE)
            colnames(first_companies)[colnames(first_companies)=="sent"] <- company
        } else {

            #Case of companies that are aggregated in the field Others
            if (first==FALSE){
                first = TRUE
                first_companies$Others = sent$sent
            }else{
                first_companies$Others = first_companies$Others + sent$sent
            }
        }
        count = count + 1
        #print(first_companies)
    }

    #TODO: remove global variables...
    first_companies <- completePeriodIds(first_companies, conf$granularity, conf)
    first_companies <- first_companies[order(first_companies$id), ]
    first_companies[is.na(first_companies)] <- 0
    print(first_companies)

    return(first_companies)

}




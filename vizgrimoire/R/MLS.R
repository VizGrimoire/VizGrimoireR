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


#############
# TODO: missing functions wrt 
#       evolution and agg values of countries and companies
#############

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
    return (paste(" m.mailing_list_url = ",repository," "))
}


GetMLSSQLCompaniesFrom <- function(i_db){
    # fields necessary for the companies analysis
    
    return(paste(" , messages_people mp, 
                   people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetMLSSQLCompaniesWhere <- function(name){
    # filters for the companies analysis
    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   m.first_date >= upc.init and
                   m.first_date < upc.end and
                   c.name = ",name, sep=""))
}

GetMLSSQLCountriesFrom <- function(i_db){
    # fields necessary for the countries analysis
    return(paste(" , messages_people mp, 
                   people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_countries upc ", sep=""))
}

GetMLSSQLCountriesWhere <- function(name){
    # filters necessary for the countries analysis

    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.country_id = c.id and
                   c.name=",name, sep=""))
}

GetMLSSQLDomainsFrom <- function(i_db) {
    return (paste(" , messages_people mp,
                   people_upeople pup,
                  ",i_db,".domains d,
                  ",i_db,".upeople_domains upd",sep=""))
}

GetMLSSQLDomainsWhere <- function(name) {
    return (paste(" m.message_ID = mp.message_id and
                    mp.email_address = pup.people_id and
                    mp.type_of_recipient=\'From\' and
                    pup.upeople_id = upd.upeople_id AND
                    upd.domain_id = d.id AND
                    m.first_date >= upd.init AND
                    m.first_date < upd.end and
                    d.name=", name, sep=""))
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
                ifelse (analysis == 'domain', paste(from, GetMLSSQLDomainsFrom(identities_db)),
                NA))))
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
                ifelse (analysis == 'company', paste(where, GetMLSSQLCompaniesWhere(value)),
                ifelse (analysis == 'country', paste(where, GetMLSSQLCountriesWhere(value)),
                ifelse (analysis == 'domain', paste(where, GetMLSSQLDomainsWhere(value)),
                NA))))
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
        sent = EvolEmailsSent(period, startdate, enddate, identities_db, type_analysis)
        senders = EvolMLSSenders(period, startdate, enddate, identities_db, type_analysis)
        repositories = EvolMLSRepositories(rfield, period, startdate, enddate, identities_db, type_analysis)
        threads = EvolThreads(period, startdate, enddate, identities_db, type_analysis)
        sent_response = EvolMLSResponses(period, startdate, enddate, identities_db, type_analysis)
        senders_response = EvolMLSSendersResponse(period, startdate, enddate, identities_db, type_analysis)
        senders_init = EvolMLSSendersInit(period, startdate, enddate, identities_db, type_analysis)
        #countries = 
        #companies =

        data = merge(sent, senders, all=TRUE)
        data = merge(data, repositories, all=TRUE)
        data = merge(data, threads, all=TRUE)
        if (nrow(sent_response) > 0){
            #in some cases not value is returned, this should be
            #used in the rest of cases, to be fixed...
            data = merge(data, sent_response, all=TRUE)
        }
        data = merge(data, senders_init, all=TRUE)

    } else {
        sent = AggEmailsSent(period, startdate, enddate, identities_db, type_analysis)
        senders = AggMLSSenders(period, startdate, enddate, identities_db, type_analysis)
        repositories = AggMLSRepositories(rfield, period, startdate, enddate, identities_db, type_analysis)
        threads = AggThreads(period, startdate, enddate, identities_db, type_analysis)
        sent_response = AggMLSResponses(period, startdate, enddate, identities_db, type_analysis)
        senders_response = AggMLSSendersResponse(period, startdate, enddate, identities_db, type_analysis)
        senders_init = AggMLSSendersInit(period, startdate, enddate, identities_db, type_analysis)

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

    if (evolutionary){
        fields = " count(distinct(m.message_ID)) as sent "
    } else {
        fields = " count(distinct(m.message_ID)) as sent,
                   DATE_FORMAT (min(m.first_date), '%Y-%m-%d') as first_date,
                   DATE_FORMAT (max(m.first_date), '%Y-%m-%d') as last_date "
    }
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = GetMLSSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
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
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        #not sure if this line is useful anymore...
        filters = GetMLSSQLReportWhere(type_analysis)
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  messages_people mp, 
                        people_upeople pup ", sep="") 
        filters <- paste(filters, " and m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' ", sep="")
    }


    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
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
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        filters = GetMLSSQLReportWhere(type_analysis)
    }
    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  messages_people mp, 
                        people_upeople pup ", sep="")
        filters <- paste(filters, " and m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' ", sep="")
    }
    
    filters = paste(filters, " and m.is_response_of is not null ", sep="")


    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
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
    if (tables == " messages m  "){
        # basic case: it's needed to add unique ids filters
        tables = paste(tables, ", messages_people mp, people_upeople pup ")
        filters = GetMLSFiltersOwnUniqueIdsMLS()
    } else {
        filters = GetMLSSQLReportWhere(type_analysis)
    }
    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  messages_people mp, 
                        people_upeople pup ", sep="")
        filters <- paste(filters, " and m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' ", sep="")
    }

    filters = paste(filters, " and m.is_response_of is null ", sep="")


    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
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

    fields = paste(" COUNT(DISTINCT(",rfield,")) AS repositories  ", sep="")
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
    filters = paste(GetMLSSQLReportWhere(type_analysis), " and m.is_response_of is not null ", sep="")

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
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

GetMLSStudies <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary, study){
    # Generic function that counts evolution/agg number of specific studies with similar
    # database schema such as domains, companies and countries

    fields = paste(' count(distinct(name)) as ', study, sep="")
    tables = paste(" messages m ", GetMLSSQLReportFrom(identities_db, type_analysis))
    filters = paste(GetMLSSQLReportWhere(type_analysis), " and m.is_response_of is null ", sep="")

    #Filtering last part of the query, not used in this case
    #filters = gsub("and\n( )+(d|c|cou|com).name =.*$", "", filters)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    q = gsub("(d|c|cou|com).name.*and", "", q)

    data <- ExecuteQuery(q)
    return(data)
}

EvolMLSDomains <- function(period, startdate, enddate, identities_db, type_analysis=list(NA,NA)){
    # Evol number of domains used
    return(GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, TRUE, 'domains'))
}

EvolMLSCountries <- function(period, startdate, enddate, identities_db, type_analysis=list(NA, NA)){
    # Evol number of countries
    return(GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, TRUE, 'countries'))
}

EvolMLSCompanies <- function(period, startdate, enddate, identities_db, type_analysis=list(NA, NA)){
    # Evol number of companies
    data <- GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, TRUE, 'companies')
    return(data)
}


AggMLSDomains <- function(period, startdate, enddate, identities_db, type_analysis=list(NA, NA)){
    # Agg number of domains
    return(GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, FALSE, 'domains'))
}

AggMLSCountries <- function(period, startdate, enddate, identities_db, type_analysis=list(NA, NA)){
    # Agg number of countries
    return(GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, FALSE, 'countries'))
}
AggMLSCompanies <- function(period, startdate, enddate, identities_db, type_analysis=list(NA, NA)){
    # Agg number of companies
    return(GetMLSStudies(period, startdate, enddate, identities_db, type_analysis, FALSE, 'companies'))
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
        mailing_lists <- run(query)
        mailing_lists_files <- run(query)
        names = mailing_lists_files
    } else {
        # TODO: not ordered yet by total messages
        q = paste("SELECT DISTINCT(mailing_list) FROM messages m
                        WHERE m.first_date >= ",startdate," AND
                        m.first_date < ",enddate)
        query <- new ("Query", sql = q)
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
    query <- new ("Query", sql = q)
    data <- run(query)
    return(data$name)
}

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

domainsNames <- function (i_db, startdate, enddate, filter=c()) {
    domains_limit = 30
    filter_domains = ""

    for (domain in filter){
        filter_domains <- paste(filter_domains, " d.name<>'", domain,
                "' AND ",sep="")
    }

    q <- paste("SELECT d.name as name, COUNT(DISTINCT(m.message_ID)) as sent
                FROM ", GetTablesDomains(i_db), "
                WHERE ", GetFiltersDomains(), " AND
                ", filter_domains, "
                m.first_date >= ",startdate," AND
                m.first_date < ",enddate,"
                GROUP BY d.name
                ORDER BY COUNT(DISTINCT(m.message_ID)) DESC LIMIT ",
                domains_limit, sep="")

    query <- new("Query", sql = q)
    data <- run(query)
    return (data$name)
}


########################
# People functions as in the old version, still to be refactored!
########################

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

GetTablesDomains <- function(i_db) {
    return (paste(GetTablesOwnUniqueIdsMLS(),',
                  ',i_db,'.domains d,
                  ',i_db,'.upeople_domains upd',sep=''))
}

GetFiltersDomains <- function() {
    return (paste(GetFiltersOwnUniqueIdsMLS(),' AND
                  pup.upeople_id = upd.upeople_id AND
                  upd.domain_id = d.id AND
                  m.first_date >= upd.init AND
                  m.first_date < upd.end'))
}

GetFiltersInit <- function() {
    filters = GetFiltersOwnUniqueIdsMLS()
    filters_init = paste(filters, " AND m.is_response_of IS NULL")
}
GetFiltersResponse <- function() {
    filters = GetFiltersOwnUniqueIdsMLS()
    filters_response = paste(filters, " AND m.is_response_of IS NOT NULL")
}



GetListPeopleMLS <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id, count(m.message_ID) total"
    tables = GetTablesOwnUniqueIdsMLS()
    filters = GetFiltersOwnUniqueIdsMLS()
    filters = paste(filters,"GROUP BY id ORDER BY total desc")
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
    q <- paste("SELECT up.id as id, up.identifier as senders,
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
    q <- paste("SELECT up.id as id, up.identifier as senders,
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
    q <- paste("SELECT up.id as id, up.identifier as senders,
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

domainTopSenders <- function(domain_name, identities_db, startdate, enddate){
    q <- paste("SELECT up.identifier as senders,
                  COUNT(DISTINCT(m.message_id)) as sent
                FROM ", GetTablesDomains(identities_db),
                ", ",identities_db,".upeople up
                WHERE ", GetFiltersDomains(), " AND
                  up.id = upd.upeople_id AND
                  m.first_date >= ",startdate," AND
                  m.first_date < ",enddate," AND
                  d.name = '",domain_name,"'
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
    }

    #TODO: remove global variables...
    first_companies <- completePeriodIds(first_companies, conf$granularity, conf)
    first_companies <- first_companies[order(first_companies$id), ]
    first_companies[is.na(first_companies)] <- 0

    return(first_companies)

}




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
# Meta functions to automatically call other functions
##############

#TBD


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

EvolEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evolution of emails sent
    return(GetEmailsSent(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSSenders <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evolution of people sending emails
    return(GetMLSSenders(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSenders <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSSendersResponse <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evolution of people sending emails
    return(GetMLSSendersResponse(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSendersResponse <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSSendersInit <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evolution of people sending emails
    return(GetMLSSendersInit(period, startdate, enddate, identities_db, type_analysis , TRUE))
}

AggMLSSendersInit <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolThreads <- function(period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails sent
    return(GetThreads(period, startdate, enddate, identities_db, type_analysis, TRUE))
}
 

AggThreads <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSRepositories <- function(rfield, period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails sent
    return(GetMLSRepositories(rfield, period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSRepositories <- function(rfield, period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSResponses <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evol number of replies
    return(GetMLSResponses(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSResponses <- function(period, startdate, enddate, identities_db, type_analysis){
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

EvolMLSInit <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evol number of messages starting a thread
    return(GetMLSInit(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


AggMLSInit <- function(period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails starting a thread
    return(GetMLSInit(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



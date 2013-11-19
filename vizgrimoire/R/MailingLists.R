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

GetSQLRepositoriesFrom <- function(){
    # tables necessary for repositories
    return (" messages m ")
}

GetSQLRepositoriesWhere <- function(repository){
    # fields necessary to match info among tables
    return (paste(" m.mailing_list_url = 'repository' "))
}


GetSQLCompaniesFrom <- function(){
    # fields necessary for the companies analysis
    
    return(paste(" messages m,
                   messages_people mp, 
                   people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetSQLCompaniesWhere <- function(){
    # filters for the companies analysis
    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   m.first_date >= upc.init and
                   m.first_date < upc.end "), sep="")
}

GetSQLCountriesFrom <- function(){
    # fields necessary for the countries analysis
    return(paste(" messages m,
                   messages_people mp, 
                   people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_countries upc ", sep=""))
}

GetSQLCountriesWhere <- function(){
    # filters necessary for the countries analysis

    return(paste(" m.message_ID = mp.message_id and
                   mp.email_address = pup.people_id and
                   mp.type_of_recipient=\'From\' and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   m.first_date >= upc.init and
                   m.first_date < upc.end "), sep="")

}

##############
# Generic functions to check evolutionary or aggregated info
# and for the execution of the final query
##############

BuildQuery <- function(period, startdate, enddate, date_field, fields, tables, filters, evolutionary){
    # Select the way to evolutionary or aggregated dataset

    q = ""

    if (evolutionary) {
         q <- GetSQLPeriod(period, date_field, fields, tables, filters,
            startdate, enddate)
    } else {
         q <- GetSQLGlobal(date_field, fields, tables, filters,
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


GetSQLReportFrom <- function(identities_db, type_analysis){
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetSQLRepositoriesFrom()),
                ifelse (analysis == 'company', paste(from, GetSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', paste(from, GetSQLCountriesFrom(identities_db)),
                NA)))
    }
    return (from)
}


GetSQLReportWhere <- function(type_analysis){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)){
        where <- ifelse (analysis == 'repository', paste(where, GetSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(where, GetSQLCompaniesWhere(value)),
                ifelse (analysis == 'country', paste(where, GetSQLCountriesWhere(value)),
                NA)))
    }
    return (where)
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
    tables = paste(" messages m ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)
    print(q)

    return(ExecuteQuery(q))
}

EvolEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis){
    # Evolution of emails sent
    return(GetEmailsSent(period, startdate, enddate, identities_db, type_analysis = list(NA, NA), TRUE))
}

AggEmailsSent <- function(period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails sent
    return(GetEmailsSent(period, startdate, enddate, identities_db, type_analysis = list(NA, NA), FALSE))
}

# Threads
GetThreads <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # Generic function that counts threads

    fields = " count(distinct(m.is_response_of)) as threads"
    tables = paste(" messages m ", GetSQLReportFrom(identities_db, type_analysis))    
    filters = GetSQLReportWhere(type_analysis)

    q <- BuildQuery(period, startdate, enddate, " m.first_date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolThreads <- function(period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails sent
    return(GetThreads(period, startdate, enddate, identities_db, type_analysis = list(NA, NA), TRUE))
}
 

AggThreads <- function(period, startdate, enddate, identities_db, type_analysis){
    # Aggregated number of emails sent
    return(GetThreads(period, startdate, enddate, identities_db, type_analysis = list(NA, NA), FALSE))
}
 


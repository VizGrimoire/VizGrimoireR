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
## AuxiliaryITS.R
##
## Queries for ITS data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Luis Cañas-Díaz <lcanas@bitergia.com>
## TODO
# issues table queries should be converted as changes table is done


##############
# Specific FROM and WHERE clauses per type of report
##############

GetITSSQLRepositoriesFrom <- function(){
    # tables necessary for repositories 
    return (", trackers t")
}

GetITSSQLRepositoriesWhere <- function(repository){
    # fields necessary to match info among tables
    return (paste(" t.url = ",repository," "))
}


GetMLSSQLCompaniesFrom <- function(i_db){
    # fields necessary for the companies analysis

    return(paste(" , people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetMLSSQLCompaniesWhere <- function(name){
    # filters for the companies analysis
    return(paste(" i.submitted_by = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   i.submitted_on >= upc.init and
                   i.submitted_on < upc.end and
                   c.name = ",name, sep=""))
}

GetMLSSQLCountriesFrom <- function(i_db){
    # fields necessary for the companies analysis

    return(paste(" , people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_companies upc", sep=""))
}   
    
GetMLSSQLCountriesWhere <- function(name){
    # filters for the companies analysis
    return(paste(" i.submitted_by = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   i.submitted_on >= upc.init and
                   i.submitted_on < upc.end and
                   c.name = ",name, sep=""))
}


##############
# Generic functions to check evolutionary or aggregated info
# and for the execution of the final query
##############

BuildQuery <- function(period, startdate, enddate, date_field, fields, tables, filters, evolutionary){
    # Select the way to evolutionary or aggregated dataset

    q = ""

    if (evolutionary) {
         q <- GetITSSQLPeriod(period, date_field, fields, tables, filters,
            startdate, enddate)
    } else {
         q <- GetITSSQLGlobal(date_field, fields, tables, filters,
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

GetITSSQLReportFrom <- function(identities_db, type_analysis){
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


GetITSSQLReportWhere <- function(type_analysis){
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
                NA)))
    }
    return (where)
}


#########
# Other generic functions
#########

#TDB

##########
# Meta functions that aggregate all evolutionary or static data in one call
##########

#TBD


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


# Generic functions to calculate the evolution of the backlog for a given
# status or set of statuses. This is based on the analysis of the 
# issues_log_xxxx table

BuildWeekDate <- function(date){
   return(paste(getISOWEEKYear(date), getISOWEEKWeek(date), sep=""))
}

GetEvolBacklogTickets <- function (period, startdate, enddate, statuses, name.logtable, filter="") {
    # Return backlog of tickets in the statuses passed as parameter
    q <- paste("SELECT DISTINCT issue_id, status, date FROM ",name.logtable," ", filter ," ORDER BY date ASC")
    query <- new("Query", sql = q)
    res <- run(query)

    pending.tickets <- data.frame()
    start = as.POSIXlt(gsub("'", "", startdate))
    end = as.POSIXlt(gsub("'", "", enddate))

    if (period == "month") {
        samples <- GetMonthsBetween(start, end, extra=TRUE)
        pending.tickets <- CountBacklogTickets(samples, res, statuses)
        colnames(pending.tickets) <- c('month', 'pending_tickets')
        posixdates = as.POSIXlt(as.numeric(pending.tickets$month), origin="1970-01-01")
        dates = as.Date(posixdates)
        dates = as.numeric(format(dates, "%Y"))*12 + as.numeric(format(dates, "%m"))
        pending.tickets$month = dates
    }
    else if (period == "week"){
        samples <- GetWeeksBetween(start, end, extra=TRUE)
        pending.tickets <- CountBacklogTickets(samples, res, statuses)
        colnames(pending.tickets) <- c('week', 'pending_tickets')
        posixdates = as.POSIXlt(as.numeric(pending.tickets$week), origin="1970-01-01")
        dates = as.Date(posixdates)
        #It's needed in this case to call a function to build the correct
        #yearweek value according to how this is done in MySQL
        dates = lapply(dates, BuildWeekDate)
        dates = as.numeric(dates)
        pending.tickets$week = dates
    }

    return(pending.tickets)
}


CountBacklogTickets <- function(samples, res, statuses){
    # return number of tickets in status = statuses per period of time
    #
    # Warning: heavy algorithm, it could be improved if the backlog is
    # calculated backwards and the data is reduced in every iteration
    #
    # Fixme: it is needed to check if there are more that a status for
    # an issue at the same time
    #
    backlog_tickets = data.frame()
    periods <- length(samples$unixtime)
    for (p in (1:periods)){

        if ( p == periods){
            break
        }

        date_unixtime <- samples$unixtime[p]
        next_unixtime_str <- samples$unixtime[p+1]

        next_date <- as.POSIXlt(as.numeric(next_unixtime_str), origin="1970-01-01")
        #print(paste("[" , date() , "] date_unixtime = ",date_unixtime, " next_date = ", next_date)) # debug mode?

        resfilter <- subset(res,res$date < next_date)

        if (nrow(resfilter) > 0){
            maxs <- aggregate(date ~ issue_id, data = resfilter, FUN = max)
            resultado <- merge(maxs, resfilter)
            # filtering by status
            total <- 0
            for (s in statuses){
                aux <- nrow(subset(resultado, resultado$status==s))
                total <- aux + total
            }
            ## print(paste("[" , date() , "] backlog tickets:", total)) # debug mode?
        }else{
            total <- 0
        }
        aux_df <- data.frame(month=date_unixtime, backlog_tickets = total)
        if (nrow(backlog_tickets)){
            backlog_tickets <- merge(backlog_tickets,aux_df, all=TRUE)
        }else{
            backlog_tickets <- aux_df
        }
    }
    return(backlog_tickets)
}



# Generic function to obtain the current photo of a given issue
# This is based on the field "status" from the issues table

GetCurrentStatus <- function(period, startdate, enddate, status){
    # This functions provides  of the status specified by 'status'
    # group by submitted date. Thus, as an example, for those issues 
    # in status = open, it is possible to know when they were submitted

    fields = paste(" count(distinct(id)) as current_", status, sep="")
    tables = " issues "
    filters = paste(" status = '", status, "' ", sep="")
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters,
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}




################
# Last activity functions
################


################
# Top functions
################

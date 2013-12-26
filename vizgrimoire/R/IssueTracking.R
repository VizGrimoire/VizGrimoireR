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
    return (paste(" i.tracker_id = t.id and t.url = ",repository," "))
}


GetITSSQLCompaniesFrom <- function(i_db){
    # fields necessary for the companies analysis

    return(paste(" , people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetITSSQLCompaniesWhere <- function(name){
    # filters for the companies analysis
    return(paste(" i.submitted_by = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   i.submitted_on >= upc.init and
                   i.submitted_on < upc.end and
                   c.name = ",name, sep=""))
}

GetITSSQLCountriesFrom <- function(i_db){
    # fields necessary for the companies analysis

    return(paste(" , people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_companies upc", sep=""))
}   
    
GetITSSQLCountriesWhere <- function(name){
    # filters for the companies analysis
    return(paste(" i.submitted_by = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
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
        from <- ifelse (analysis == 'repository', paste(from, GetITSSQLRepositoriesFrom()),
                ifelse (analysis == 'company', paste(from, GetITSSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', paste(from, GetITSSQLCountriesFrom(identities_db)),
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
        where <- ifelse (analysis == 'repository', paste(where, GetITSSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(where, GetITSSQLCompaniesWhere(value)),
                ifelse (analysis == 'country', paste(where, GetITSSQLCountriesWhere(value)),
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

GetCurrentStatus <- function(period, startdate, enddate, identities_db, status, evolutionary){
    # This functions provides  of the status specified by 'status'
    # group by submitted date. Thus, as an example, for those issues 
    # in status = open, it is possible to know when they were submitted

    fields = paste(" count(distinct(id)) as current_", status, sep="")
    tables = paste(" issues ", GetITSReportFrom(identities_db, type_analysis), sep="")
    filters = paste(" status = '", status, "' and ", GetITSSQLReportWhere(type_analysis) , sep="")
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters,
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#TODO: check the differences between function GetCurrentOpened and GetEvolClosed,
# GetEvolOpened, etc... in some cases such as opened, openers, closed, closers, 
# changed and changers is more than enough to just count changes in table changes
# opened when the issue was submitted (and submitted by) and closers providing the
# closed condition. Do we get whe same results if using the Backlog table?

GetOpened <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #This function returns the evolution or agg number of opened issues
    #This function can be also reproduced using the Backlog function.
    #However this function is less time expensive.
    fields = " count(distinct(i.id)) as opened "
    tables = paste(" issues i ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")
    filters = GetITSSQLReportWhere(type_analysis) 
    q <- BuildQuery(period, startdate, enddate, " submitted_on ", fields, tables, filters, evolutionary)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

AggIssuesOpened <- function(period, startdate, enddate, identities_db, type_analysis){
    # Returns aggregated number of opened issues
    return(GetOpened(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


EvolIssuesOpened <- function(period, startdate, enddate, identities_db, type_analysis){
    #return(GetEvolBacklogTickets(period, startdate, enddate, status, name.logtable, filter))
    return(GetOpened(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


GetOpeners <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary, closed_condition){
    #This function returns the evolution or agg number of people opening issues
    fields = " count(distinct(pup.upeople_id)) as openers "
    tables = paste(" issues i ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")
    filters = GetITSSQLReportWhere(type_analysis)

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id ", sep="")
    }

    q <- BuildQuery(period, startdate, enddate, " submitted_on ", fields, tables, filters, evolutionary)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)

}

AggIssuesOpeners <- function(period, startdate, enddate, identities_db, type_analysis){
    # Returns aggregated number of opened issues
    return(GetOpeners(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


EvolIssuesOpeners <- function(period, startdate, enddate, identities_db, type_analysis){
    #return(GetEvolBacklogTickets(period, startdate, enddate, status, name.logtable, filter))
    return(GetOpeners(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


GetClosed <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary, closed_condition){
    #This function returns the evolution or agg number of closed issues
    #This function can be also reproduced using the Backlog function.
    #However this function is less time expensive.
    fields = " count(distinct(i.id)) as closed "
    tables = paste(" issues i, changes ch ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")

    filters = paste(" i.id = ch.issue_id and ", closed_condition, sep="") 
    filters_ext = GetITSSQLReportWhere(type_analysis)
    if (filters_ext != ""){
        filters = paste(filters, " and ", filters_ext, sep="")
    }
 
    #Action needed to replace issues filters by changes one
    filters = gsub("i.submitted", "ch.changed", filters)
    
    q <- BuildQuery(period, startdate, enddate, " ch.changed_on ", fields, tables, filters, evolutionary)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

AggIssuesClosed <- function(period, startdate, enddate, identities_db, type_analysis, closed_condition){
    # Returns aggregated number of closed issues
    return(GetClosed(period, startdate, enddate, identities_db, type_analysis, FALSE, closed_condition))
}


EvolIssuesClosed <- function(period, startdate, enddate, identities_db, type_analysis, closed_condition){
    #return(GetEvolBacklogTickets(period, startdate, enddate, status, name.logtable, filter))
    return(GetClosed(period, startdate, enddate, identities_db, type_analysis, TRUE, closed_condition))
}


GetClosers <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary, closed_condition){
    #This function returns the evolution or agg number of closed issues
    #This function can be also reproduced using the Backlog function.
    #However this function is less time expensive.
    fields = " count(distinct(pup.upeople_id)) as closers "
    tables = paste(" issues i, changes ch ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")

    #closed condition filters
    filters = paste(" i.id = ch.issue_id and ", closed_condition, sep="")
    filters_ext = GetITSSQLReportWhere(type_analysis)
    if (filters_ext != ""){
        filters = paste(filters, " and ", filters_ext, sep="")
    }
 
    #unique identities filters
    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id ", sep="")
    }

    #Action needed to replace issues filters by changes one
    filters = gsub("i.submitted", "ch.changed", filters)


    q <- BuildQuery(period, startdate, enddate, " ch.changed_on ", fields, tables, filters, evolutionary)
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

AggIssuesClosers <- function(period, startdate, enddate, identities_db, type_analysis, closed_condition){
    # Returns aggregated number of closed issues
    return(GetClosers(period, startdate, enddate, identities_db, type_analysis, FALSE, closed_condition))
}


EvolIssuesClosers <- function(period, startdate, enddate, identities_db, type_analysis, closed_condition){
    #return(GetEvolBacklogTickets(period, startdate, enddate, status, name.logtable, filter))
    return(GetClosers(period, startdate, enddate, identities_db, type_analysis, TRUE, closed_condition))
}


GetChanged <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #This function returns the evolution or agg number of changed issues
    #This function can be also reproduced using the Backlog function.
    #However this function is less time expensive.
    fields = " count(distinct(ch.id)) as changed "
    tables = paste(" issues i, changes ch ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")

    filters = " i.id = ch.issue_id "
    filters_ext = GetITSSQLReportWhere(type_analysis)
    if (filters_ext != ""){
        filters = paste(filters, " and ", filters_ext, sep="")
    }

    #Action needed to replace issues filters by changes one
    filters = gsub("i.submitted", "ch.changed", filters)

    q <- BuildQuery(period, startdate, enddate, " ch.changed_on ", fields, tables, filters, evolutionary)
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

AggIssuesChanged <- function(period, startdate, enddate, identities_db, type_analysis){
    # Returns aggregated number of closed issues
    return(GetChanged(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


EvolIssuesChanged <- function(period, startdate, enddate, identities_db, type_analysis){
    return(GetChanged(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetChangers <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #This function returns the evolution or agg number of changed issues
    #This function can be also reproduced using the Backlog function.
    #However this function is less time expensive.
    fields = " count(distinct(pup.upeople_id)) as changers "
    tables = paste(" issues i, changes ch ", GetITSSQLReportFrom(identities_db, type_analysis), sep="")

    filters = " i.id = ch.issue_id "
    filters_ext = GetITSSQLReportWhere(type_analysis)
    if (filters_ext != ""){
        filters = paste(filters, " and ", filters_ext, sep="")
    }

    #unique identities filters
    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ", people_upeople pup", sep="")
        filters <- paste(filters, " and i.submitted_by = pup.people_id ", sep="")
    }


    #Action needed to replace issues filters by changes one
    filters = gsub("i.submitted", "ch.changed", filters)

    q <- BuildQuery(period, startdate, enddate, " ch.changed_on ", fields, tables, filters, evolutionary)
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

AggIssuesChangers <- function(period, startdate, enddate, identities_db, type_analysis){
    # Returns aggregated number of closed issues
    return(GetChangers(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


EvolIssuesChangers <- function(period, startdate, enddate, identities_db, type_analysis){
    return(GetChangers(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

###############
# Lists of repositories, companies, countries and other analysis
###############

GetReposNameITS <- function(startdate, enddate) {
    # List the url of each of the repositories analyzed
    # Those are order by the number of opened issues (dec order)
    q <- paste (" SELECT t.url as name
                  FROM issues i, 
                       trackers t
                  WHERE i.tracker_id=t.id and
                        i.submitted_on >= ", startdate, " and
                        i.submitted_on < ", enddate, "
                  GROUP BY t.url 
                  ORDER BY count(distinct(i.id)) DESC ", sep="")
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetCountriesNamesITS <- function (startdate, enddate, identities_db, closed_condition) {
    # List each of the countries analyzed
    # Those are order by number of closed issues
    q <- paste("select cou.name
                    from issues i, 
                         changes ch,
                         people_upeople pup,
                         ", identities_db, ".upeople_countries upc,
                         ", identities_db, ".countries cou
                    where i.id = ch.issue_id and
                          ch.changed_by = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          upc.country_id = cou.id and
                          ch.changed_on >= ", startdate, " and
                          ch.changed_on < ", enddate," and
                          ", closed_condition, "
                          group by cou.name 
                          order by count(distinct(i.id)) desc", sep="") 
    print(q)
    query <- new("Query", sql = q)
    data <- run(query)      
    return (data)             
}

GetCompaniesNameITS <- function(startdate, enddate, identities_db, closed_condition) {
    # list each of the companies analyzed
    # those are order by number of closed issues
        q <- paste("select c.name
                    from issues i, 
                         changes ch,
                         people_upeople pup,
                         ", identities_db, ".upeople_companies upc,
                         ", identities_db, ".companies c
                    where i.id = ch.issue_id and
                          ch.changed_by = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          upc.company_id = c.id and
                          ch.changed_on >= ", startdate, " and
                          ch.changed_on < ", enddate," and
                          ", closed_condition, "
                          group by c.name 
                          order by count(distinct(i.id)) desc", sep="")
    print(q)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}




################
# Last activity functions
################


##
## GetDiffClosedDays
##
## Get differences in number of closed tickets between two periods.
##  - date: final date of the two periods.
##  - days: number of days for each period.
##  - closed_condition: SQL string to define the condition of "closed"
##     for a ticket
## Example of parameters, for analizing the difference during the last
##  two weeks for the day 2013-11-25:
##  (date="2013-11-25", days=7, closed_condition=...)
##
GetDiffClosedDays <- function(date, days, closed_condition){
    # This function provides the percentage in activity between two periods
    chardates = GetDates(date, days)
    lastclosed = AggIssuesClosed(period, chardates[2], chardates[1], identities_db, closed_condition)
    #lastclosed = StaticNumClosed(closed_condition, chardates[2], chardates[1])
    lastclosed = as.numeric(lastclosed[1])
    prevclosed = AggIssuesClosed(period, chardates[3], chardates[2], identities_db, closed_condition)
    #prevclosed = StaticNumClosed(closed_condition, chardates[3], chardates[2])
    prevclosed = as.numeric(prevclosed[1])
    diffcloseddays = data.frame(diff_netclosed = numeric(1), percentage_closed = numeric(1))

    diffcloseddays$diff_netclosed = lastclosed - prevclosed
    diffcloseddays$percentage_closed = GetPercentageDiff(prevclosed, lastclosed)

    colnames(diffcloseddays) <- c(paste("diff_netclosed","_",days, sep=""), paste("percentage_closed","_",days, sep=""))

    return (diffcloseddays)
}

##
## GetDiffClosersDays
##
## Get differences in number of ticket closers between two periods.
##  - date: final date of the two periods.
##  - days: number of days for each period.
##  - closed_condition: SQL string to define the condition of "closed"
##     for a ticket
## Example of parameters, for analizing the difference during the last
##  two weeks for the day 2013-11-25:
##  (date="2013-11-25", days=7, closed_condition=...)
##
GetDiffClosersDays <- function(date, days, closed_condition){
    # This function provides the percentage in activity between two periods

    chardates = GetDates(date, days)
    lastclosers = AggIssuesClosers(period, chardates[2], chardates[1], identities_db, closed_condition)
    #lastclosers = StaticNumClosers(closed_condition, chardates[2], chardates[1])
    lastclosers = as.numeric(lastclosers[1])
    prevclosers = AggIssuesClosers(period, chardates[3], chardates[2], identities_db, closed_condition)
    #prevclosers = StaticNumClosers(closed_condition, chardates[3], chardates[2])
    prevclosers = as.numeric(prevclosers[1])
    diffclosersdays = data.frame(diff_netclosers = numeric(1), percentage_closers = numeric(1))

    diffclosersdays$diff_netclosers = lastclosers - prevclosers
    diffclosersdays$percentage_closers = GetPercentageDiff(prevclosers, lastclosers)

    colnames(diffclosersdays) <- c(paste("diff_netclosers","_",days, sep=""), paste("percentage_closers","_",days, sep=""))

    return (diffclosersdays)
}


GetLastActivityITS <- function(days, closed_condition) {
    # opened issues
    q <- paste("select count(*) as opened_",days,"
                from issues
                where submitted_on >= (
                      select (max(submitted_on) - INTERVAL ",days," day)
                      from issues)", sep="");
    query <- new("Query", sql = q)
    data1 = run(query)

    # closed issues
    q <- paste("select count(distinct(issue_id)) as closed_",days,"
                from changes
                where  ", closed_condition,"
                and changed_on >= (
                      select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="");
    query <- new("Query", sql = q)
    data2 = run(query)

    # closers
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as closers_",days,"
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by and
                 changed_on >= (
                     select (max(changed_on) - INTERVAL ",days," day)
                      from changes) AND ", closed_condition, sep="");

    query <- new ("Query", sql = q)
    data3 <- run(query)

    # people_involved    
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as changers_",days,"
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by and
                 changed_on >= (
                     select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="");
    query <- new ("Query", sql = q)
    data4 <- run(query)

    agg_data = merge(data1, data2)
    agg_data = merge(agg_data, data3)

    return (agg_data)

}


################
# Top functions
################

GetTopClosersByAssignee <- function(days = 0, startdate, enddate, identities_db, filter = c("")) {

    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'", aff ,"' and ", sep="")
    }

    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    q <- paste("SELECT up.id as id, 
                       up.identifier as closers, 
                       count(distinct(ill.issue_id)) as closed 
                FROM people_upeople pup, 
                     ", identities_db, ".upeople_companies upc, 
                     ", identities_db, ".upeople up, 
                     ", identities_db, ".companies com,
                     issues_log_launchpad ill 
                WHERE ill.assigned_to = pup.people_id and 
                      pup.upeople_id = up.id and 
                      up.id = upc.upeople_id and 
                      upc.company_id = com.id and
                      ", affiliations, "
                      ill.date >= upc.init and 
                      ill.date < upc.end and 
                      ill.change_id  in ( 
                                     select id 
                                     from changes 
                                     where new_value='Fix Committed' and 
                                           changed_on>=", startdate, " and 
                                           changed_on<", enddate, " ", date_limit,") 
                GROUP BY up.identifier 
                ORDER BY closed desc limit 10;", sep="")

    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetCompanyTopClosers <- function(company_name, startdate, enddate,
        identities_db, filter = c('')) {
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " AND up.identifier<>'",aff,"' ",sep='')
    }
    q <- paste("SELECT up.id as id, up.identifier as closers,
                       COUNT(DISTINCT(c.id)) as closed
                FROM ", GetTablesCompaniesITS(identities_db),",
                     ",identities_db,".companies com,
                     ",identities_db,".upeople up
                WHERE ", GetFiltersCompaniesITS()," AND ", closed_condition, "
                      AND pup.people_id = up.id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND changed_on >= ",startdate," AND changed_on < ",enddate,
                      affiliations, "
                GROUP BY changed_by ORDER BY closed DESC LIMIT 10;",sep='')
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


GetTopClosers <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {

    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'", aff ,"' and ", sep="")
    }

    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    q <- paste("SELECT up.id as id, up.identifier as closers,
                       count(distinct(c.id)) as closed
                FROM ",GetTablesCompaniesITS(identities_db), ", ",
                     identities_db,".companies com,
                     ",identities_db,".upeople up
                WHERE ",GetFiltersCompaniesITS() ," and
                      ", affiliations, "
                      upc.company_id = com.id and
                      c.changed_by = pup.people_id and
                      pup.upeople_id = up.id and
                      c.changed_on >= ", startdate, " and
                      c.changed_on < ", enddate, " and ",
                      closed_condition, " ", date_limit, "
                GROUP BY up.identifier
                ORDER BY closed desc
                LIMIT 10;", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTopOpeners <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {  
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'", aff ,"' and ", sep="")
    }

    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(submitted_on) from issues limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, submitted_on)<",days)
    }

    q <- paste("SELECT up.id as id, up.identifier as openers,
                    count(distinct(i.id)) as opened
                FROM ",GetTablesCompaniesITS(identities_db,'issues'), ", ",
                    identities_db,".companies com,
                    ",identities_db,".upeople up
                WHERE ",GetFiltersCompaniesITS('issues') ," and
                    ", affiliations, "
                    upc.company_id = com.id and
                    pup.upeople_id = up.id and
                    i.submitted_on >= ", startdate, " and
                    i.submitted_on < ", enddate,
                    date_limit, "
                    GROUP BY up.identifier
                    ORDER BY opened desc
                    LIMIT 10;", sep="")
    query <- new ("Query", sql = q)
    print(q)
    data <- run(query)
    return (data)
}




#################
# Micro studies
#################

EvolBMIIndex <- function(period, startdate, enddate, identities_db, type_analysis, closed_condition){
    #Metric based on chapter 4.3.1
    #Metrics and Models in Software Quality Engineering by Stephen H. Kan

    #This will fail if dataframes have different lenght (to be fixe)
    closed = EvolIssuesClosed(period, startdate, enddate, identities_db, type_analysis, closed_condition)
    print(closed)
    opened = EvolIssuesOpened(period, startdate, enddate, identities_db, type_analysis)
    print(opened)
    evol_bmi = (closed$closed / opened$opened) * 100

    closed$closers <- NULL
    opened$openers <- NULL

    data = merge(closed, opened, ALL=TRUE)
    data = data.frame(data, evol_bmi)
    return (data)
}


MarkovChain<-function()
{
    #warning: this function needs some more attention...
    # some variables at the end are not used
    q<-paste("select distinct(new_value) as value
              from changes 
              where field like '%status%'")

    query <- new ("Query", sql = q)
    status <- run(query)

    print(status)
    T<-status[order(status$value),]
    T1<-gsub("'", "", T)

    print(T1)
    new_value<-function(old)
    {
        q<-paste("select old_value, new_value, count(*) as issue
                  from changes 
                  where field like '%status%' and
                        old_value like '%", old , "%' 
                  group by old_value, new_value;", sep="")

        query <- new ("Query", sql = q)
        table <- run(query)
        f<-table$issue/sum(table$issue)
        x<-cbind(table,f)
        x1<-gsub("'", "",x$new_value)
        x[,2]<-x1

        i<-0
        all<-0
        end<-NULL

        for( i in 1:length(T1)){
            if(is.element(T1[i],x$new_value)){
                i<-i+1
            }
            else{
                c<-data.frame(old_value=0,new_value=T1[i],issue=0,f=0)
                x<-rbind(x,c)
                i<-i+1
            }
        }
        good<-x[order(x$new_value),]
        return(good)
    }

    j<-0
    all<-c()
    markov_result = list()

    for( j in 1:length(T1)) {
        v<-new_value(T1[j])
        markov_result[[T1[j]]] <- v
        good<-v[order(v$new_value),]
        g<-good$f
        all<-c(all,g)
        j<-j+1
    }
    #MARKOV<-matrix(all,ncol=12,nrow=12,byrow=TRUE)

    #print(MARKOV)
    #colnames(MARKOV)<-v$new_value
    #rownames(MARKOV)<-v$new_value
    #return(MARKOV)
    return(markov_result)
}


GetClosedSummaryCompanies <- function(period, startdate, enddate, identities_db, closed_condition, num_companies){

    # All companies info
    q = paste(
         "SELECT com.name as name,
                 YEARWEEK( changed_on , 3 ) AS week,
                 COUNT(DISTINCT(issue_id)) AS closed
         FROM changes c,
              people_upeople pup,
              ",identities_db,".upeople_companies upc ,
              ",identities_db,".companies com
         WHERE changed_on >=",startdate," AND
               changed_on < ",enddate,"  AND
               pup.people_id = c.changed_by AND
               pup.upeople_id = upc.upeople_id AND
               changed_on >= upc.init AND
               changed_on < upc.end  AND
               ",closed_condition,"  AND
               upc.company_id = com.id
         GROUP BY com.name,
                  YEARWEEK( changed_on , 3 )
         ORDER BY com.name,
                  YEARWEEK( changed_on , 3 );", sep="")
         #",closed_condition,"  AND
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    print("Companies name")
    companies  <- GetCompaniesNameITS(startdate, enddate, identities_db, closed_condition, c("-Bot", "-Individual", "-Unknown"))
    companies <- companies$name

    count = 1
    first_companies = data.frame()
    first = TRUE
    for (company in companies){
        # Cleaning data
        print(company)
        company_data = subset(data, data$name %in% company)
        company_data <- completePeriodIds(company_data, conf$granularity, conf)
        company_data <- company_data[order(company_data$id), ]
        company_data[is.na(company_data)] <- 0
        company_data$name <- NULL

        # Up to here, everything's correct, dataset is as expected
        # In the following I should move to merge companies and others
        # as similarly done in mls and scm
        if (count <= num_companies -1){
            # Case of companies with entity in the dataset
            if (first){
                first = FALSE
                first_companies = company_data
            }
            first_companies = merge(first_companies, company_data, all=TRUE)
            print(first_companies)
            colnames(first_companies)[colnames(first_companies)=="closed"] <- company

        } else {
            #Case of companies that are aggregated in the field Others
            if (first==FALSE){
                first = TRUE
                first_companies$Others = company_data$closed
            }else{
                first_companies$Others = first_companies$Others + company_data$closed
            }
        }
        count = count + 1
    }

    return(first_companies)
}


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


GetTablesOwnUniqueIdsITS <- function(table='') {
    tables = 'changes c, people_upeople pup'
    if (table == "issues") tables = 'issues i, people_upeople pup'
    return (tables)
}

GetFiltersOwnUniqueIdsITS <- function (table='') {
    filters = 'pup.people_id = c.changed_by'
    if (table == "issues") filters = 'pup.people_id = i.submitted_by'
    return (filters) 
}

GetEvolMetricsITS <- function (fields, period, startdate, enddate, filters='') {    
    tables = GetTablesOwnUniqueIdsITS()
    idfilters = GetFiltersOwnUniqueIdsITS()
    if (filters!='') idfilters = paste(idfilters,'AND',filters)
    q <- GetSQLPeriod(period,'changed_on', fields, tables, idfilters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)	
}

GetEvolClosed <- function (closed_condition, period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(issue_id)) AS closed, 
              COUNT(DISTINCT(pup.upeople_id)) as closers'    
    return (GetEvolMetricsITS(fields, period, startdate, enddate, closed_condition));    
}

GetEvolChanged <- function (period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(issue_id)) AS changed, 
              COUNT(DISTINCT(pup.upeople_id)) as changers'
    return (GetEvolMetricsITS(fields, period, startdate, enddate));    
}

GetEvolOpened<- function (period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(id)) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) as openers'
    tables = "issues i, people_upeople pup"
    filters = "pup.people_id = i.submitted_by"
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)	
}


GetEvolBMIIndex <- function(closed_condition, period, startdate, enddate){
    #Metric based on chapter 4.3.1
    #Metrics and Models in Software Quality Engineering by Stephen H. Kan

    #This will fail if dataframes have different lenght (to be fixe)

    closed = GetEvolClosed(closed_condition, period, startdate, enddate)
    opened = GetEvolOpened(period, startdate, enddate)

    evol_bmi = (closed$closed / opened$opened) * 100

    closed$closers <- NULL
    opened$openers <- NULL

    data = merge(closed, opened, ALL=TRUE)
    data = data.frame(data, evol_bmi)
    return (data)
}

GetEvolReposITS <- function(period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(tracker_id)) AS repositories'
    tables = 'issues'
    filters = ''
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTablesCompaniesITS <- function (i_db, table='') {
    tables = GetTablesOwnUniqueIdsITS(table)
    tables = paste(tables,',',i_db,'.upeople_companies upc',sep='')    
}

GetTablesCountriesITS <- function (i_db,table='') {
    tables = GetTablesOwnUniqueIdsITS(table)
    tables = paste(tables,',',i_db,'.upeople_countries upc',sep='')    
}

GetFiltersCompaniesITS <- function (table='') {
    filters = GetFiltersOwnUniqueIdsITS(table)
    filters = paste(filters,"AND pup.upeople_id = upc.upeople_id")
    if (table == 'issues') {
        filters = paste(filters,"AND submitted_on >= upc.init AND submitted_on < upc.end")
    } else {
	    filters = paste(filters,"AND changed_on >= upc.init AND changed_on < upc.end")
	}
}

GetFiltersCountriesITS <- function (table='') {
    filters = GetFiltersOwnUniqueIdsITS(table)
    filters = paste(filters,"AND pup.upeople_id = upc.upeople_id")
}

GetEvolCompaniesITS <- function(period, startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.company_id)) AS companies'
    tables = GetTablesCompaniesITS(identities_db)
    filters = GetFiltersCompaniesITS()
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetEvolCountriesITS <- function(period, startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.country_id)) AS countries'
    tables = GetTablesCountriesITS(identities_db)
    filters = GetFiltersCountriesITS()
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)    
    data <- run(query)
    return (data)
}

GetTablesReposITS <- function (table='') {
    return (paste(GetTablesOwnUniqueIdsITS(table),",issues,trackers"))
}

GetFiltersReposITS <- function (table='') {
    filters = paste(GetFiltersOwnUniqueIdsITS(table),
            "AND c.issue_id = issues.id AND issues.tracker_id = trackers.id")    
    return(filters)    
}

GetEvolReposITS <- function(period, startdate, enddate) {        
    fields = 'COUNT(DISTINCT(trackers.url)) AS repositories'
    tables= GetTablesReposITS()
    filters = GetFiltersReposITS()

    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticITS <- function (closed_condition, startdate, enddate) {
   
    #TODO: to be refactored similar to the rest of the code
    q = "SELECT count(distinct(pup.upeople_id)) as allhistory_participants from people_upeople pup"
    query <- new("Query", sql = q)
    data0 = run(query)
 
    fields = "COUNT(*) as tickets,
              COUNT(*) as opened,
              COUNT(distinct(pup.upeople_id)) as openers,
              DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date"
    tables = 'issues, people_upeople pup'
    filters = 'issues.submitted_by = pup.people_id'
    q = GetSQLGlobal('submitted_on',fields,tables, filters, startdate, enddate)
    
    query <- new ("Query", sql = q)
    data <- run(query)
	
    fields = 'COUNT(DISTINCT(pup.upeople_id)) as closers,
              COUNT(DISTINCT(issue_id)) as closed'
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(),"AND",closed_condition)
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    fields = 'COUNT(DISTINCT(pup.upeople_id)) as changers,
              COUNT(DISTINCT(issue_id)) as changed'
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS())
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    q <- paste ("SELECT url, name as type FROM trackers t JOIN 
                 supported_trackers s ON t.type = s.id limit 1")	
    query <- new ("Query", sql = q)
    data6 <- run(query)
    
    q <- paste ("SELECT count(*) as repositories FROM trackers")
    query <- new ("Query", sql = q)
    data7 <- run(query)
    
    agg_data = merge(data0, data)
    agg_data = merge(agg_data, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data6)
    agg_data = merge(agg_data, data7)
    return(agg_data)
}

GetDates <- function(init_date, days) {
    # WARNING: COPIED FROM SCM.R, THIS FUNCTION SHOULD BE REMOVED
    # This functions returns an array with three dates
    # First: init_date
    # Second: init_date - days
    # Third: init_date - days - days
    enddate = gsub("'", "", init_date)

    enddate = as.Date(enddate)
    startdate = enddate - days
    prevdate = enddate - days - days

    chardates <- c(paste("'", as.character(enddate),"'", sep=""),
                   paste("'", as.character(startdate), "'", sep=""),
                   paste("'", as.character(prevdate), "'", sep=""))
    return (chardates)
}

GetPercentageDiff <- function(value1, value2){
    # WARNING: COPIED FROM SCM.R, THIS FUNCTION SHOULD BE REMOVED
    # This function returns whe % diff between value 1 and value 2.
    # The difference could be positive or negative, but the returned value
    # is always > 0

    percentage = 0
    print(paste("prevcommits=", value1))
    print(paste("lastcommits=",value2))

    if (value1 < value2){
        diff = value2 - value1
        percentage = as.integer((diff/value1) * 100)
    }
    if (value1 > value2){
        percentage = as.integer((1-(value2/value1)) * 100)
    }
    return(percentage)
}


StaticNumClosed <- function(closed_condition, startdate, enddate){
    fields = ' COUNT(DISTINCT(issue_id)) as closed'
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(),"AND",closed_condition)
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)
    query <- new ("Query", sql = q)
    data1 <- run(query)
}

GetDiffClosedDays <- function(period, init_date, days, closed_condition){
    # This function provides the percentage in activity between two periods
    chardates = GetDates(init_date, days)
    lastclosed = StaticNumClosed(closed_condition, chardates[2], chardates[1])
    lastclosed = as.numeric(lastclosed[1])
    prevclosed = StaticNumClosed(closed_condition, chardates[3], chardates[2])
    prevclosed = as.numeric(prevclosed[1])
    diffcloseddays = data.frame(diff_netclosed = numeric(1), percentage_closed = numeric(1))

    diffcloseddays$diff_netclosed = lastclosed - prevclosed
    diffcloseddays$percentage_closed = GetPercentageDiff(prevclosed, lastclosed)

    colnames(diffcloseddays) <- c(paste("diff_netclosed","_",days, sep=""), paste("percentage_closed","_",days, sep=""))

    return (diffcloseddays)
}

StaticNumClosers <- function(closed_condition, startdate, enddate){
    # closers
    fields = 'COUNT(DISTINCT(pup.upeople_id)) as closers '
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(),"AND",closed_condition)
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)
    query <- new ("Query", sql = q)
    data1 <- run(query)
    return (data1)
}

GetDiffClosersDays <- function(period, init_date, days, closed_condition){
    # This function provides the percentage in activity between two periods

    chardates = GetDates(init_date, days)
    lastclosers = StaticNumClosers(closed_condition, chardates[2], chardates[1])
    lastclosers = as.numeric(lastclosers[1])
    prevclosers = StaticNumClosers(closed_condition, chardates[3], chardates[2])
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
                      from issues)", sep="")
    query <- new("Query", sql = q)
    data1 = run(query)
    
    # closed issues
    q <- paste("select count(distinct(issue_id)) as closed_",days,"
                from changes
                where  ", closed_condition,"
                and changed_on >= (
                      select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="")
    query <- new("Query", sql = q)
    data2 = run(query)

    # closers
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as closers_",days,"
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by and
                       changed_on >= (
                       select (max(changed_on) - INTERVAL ",days," day)
                       from changes) AND", closed_condition, sep="")
 
     query <- new ("Query", sql = q)
     data3 <- run(query)



    # people_involved    
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as changers_",days,"
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by and
                 changed_on >= (
                     select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="")
                 
    query <- new ("Query", sql = q)
    data4 <- run(query)

    agg_data = merge(data1, data2)
    agg_data = merge(agg_data, data3)
    agg_data = merge(agg_data, data4)

    return (agg_data)

}

GetStaticCompaniesITS  <- function(startdate, enddate, identities_db) {    
    fields = 'COUNT(DISTINCT(upc.company_id)) AS companies'
    tables = GetTablesCompaniesITS(identities_db)
    filters = GetFiltersCompaniesITS()
    q <- GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)               
}

GetStaticCountriesITS  <- function(startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.country_id)) AS countries'
    tables = GetTablesCountriesITS(identities_db)
    filters = GetFiltersCountriesITS()
    q <- GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)               
}

# Top
## TODO: use last activity subquery
GetTopClosers <- function(days = 0, startdate, enddate, identities_db, filter = c("")) {
    
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

GetTopOpeners <- function(days = 0, startdate, enddate, identities_db, filter = c("")) {    
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

#
# REPOSITORIES
#

GetReposNameITS <- function() {
    # q <- paste ("select SUBSTRING_INDEX(url,'/',-1) AS name FROM trackers")
    q <- paste ("SELECT url AS name FROM trackers")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolClosed <- function(repo, closed_condition, period, startdate, enddate){    
    fields = 'COUNT(DISTINCT(issue_id)) AS closed, 
              COUNT(DISTINCT(pup.upeople_id)) AS closers'
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),'AND',closed_condition,
            "AND trackers.url=",repo)    
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolChanged <- function(repo, period, startdate, enddate){
    fields = 'COUNT(DISTINCT(c.issue_id)) AS changed,
              COUNT(DISTINCT(pup.upeople_id)) AS changers'
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),"AND trackers.url=",repo)
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolOpened <- function(repo, period, startdate, enddate){
    fields = "COUNT(submitted_by) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = "issues, trackers, people_upeople pup"
    filters = paste("trackers.url=",repo,"                      
                     AND issues.tracker_id = trackers.id
                     AND pup.people_id = issues.submitted_by")
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
                      startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolBMIIndex <- function(repo, closed_condition, period, startdate, enddate){
    #This will fail if dataframes have different lenght (to be fixe)


    closed = GetRepoEvolClosed(repo, closed_condition, period, startdate, enddate)
    opened = GetRepoEvolOpened(repo, period, startdate, enddate)

    evol_bmi = (closed$closed / opened$opened) * 100
    
    closed$closers <- NULL
    opened$openers <- NULL

    data = merge(closed, opened, ALL=TRUE)
    data = data.frame(data, evol_bmi)
    return (data)
}


GetStaticRepoITS <- function (repo, startdate, enddate) {
    fields = "COUNT(submitted_by) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = "issues, trackers, people_upeople pup"
    filters = paste("trackers.url=",repo,"          
                    AND issues.tracker_id = trackers.id
                    AND pup.people_id = issues.submitted_by")
    
    q <- GetSQLGlobal('submitted_on',fields, tables, 
            filters, startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    
    fields = "COUNT(DISTINCT(pup.upeople_id)) as closers, 
              COUNT(DISTINCT(issue_id)) as closed"
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),'AND',closed_condition,
            "AND trackers.url=",repo)    
    q <- GetSQLGlobal('changed_on',fields, tables, 
            filters, startdate, enddate)
                         
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    fields = "COUNT(DISTINCT(pup.upeople_id)) as changers,
              COUNT(DISTINCT(issue_id)) as changed"
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),"AND trackers.url=",repo)    
    q <- GetSQLGlobal('changed_on',fields, tables, 
            filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    agg_data = merge(data, data1)
    agg_data = merge(agg_data, data2)
    return(agg_data)
}


#
# Companies
#
# TODO: Strange companies name order using issues and not closed like countries
GetCompaniesNameITS <- function(startdate, enddate, identities_db, closed_condition, filter=c()) {
    # companies_limit = 30    
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'",aff,"' and ",sep="")
    }
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
                    
    q <- paste ("SELECT com.name
                 FROM ", tables, "
                 WHERE ", GetFiltersCompaniesITS()," AND
                 com.id = upc.company_id and
                 ",affiliations,"
                 c.changed_on >= ", startdate, " AND
                 c.changed_on < ", enddate, " AND
                 ", closed_condition,"
                 group by com.name
                 order by count(distinct(c.issue_id)) desc", sep="")
    print(q)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCompanyClosed <- function(company_name, closed_condition, period, 
        startdate, enddate, identities_db, evol){
    
    fields = "COUNT(DISTINCT(issue_id)) AS closed,
              COUNT(DISTINCT(pup.upeople_id)) AS closers"
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
    filters = paste(GetFiltersCompaniesITS()," AND ",closed_condition,"
                AND upc.company_id = com.id
                AND com.name = ",company_name,"")
    if (evol) {
        q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    } else {
        q <- GetSQLGlobal('changed_on', fields, tables, filters, 
                            startdate, enddate)
    }
    return (q) 
}

GetCompanyEvolClosed <- function(company_name, closed_condition, period, 
        startdate, enddate, identities_db){
    q <- GetCompanyClosed (company_name, closed_condition, period, 
                    startdate, enddate, identities_db, TRUE)
    print(q)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCompanyChanged <- function(company_name, period, startdate, enddate, identities_db, evol){
    
    fields = "COUNT(DISTINCT(issue_id)) AS changed,
            COUNT(DISTINCT(pup.upeople_id)) AS changers"
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
    filters = paste(GetFiltersCompaniesITS(), 
            "AND upc.company_id = com.id AND com.name = ",company_name,"")
    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
                startdate, enddate)
    } else {
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)            
}

GetCompanyEvolChanged <- function(company_name, period, startdate, enddate, identities_db){    
    q <- GetCompanyChanged(company_name, period, startdate, enddate, identities_db, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)    
}

GetCompanyOpened <- function(company_name, period, startdate, enddate, identities_db, evol){    
    q=''
    fields = "COUNT(submitted_by) AS opened,
            COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = paste("issues, people_upeople pup,",
            identities_db,".upeople_companies upc,",
            identities_db,".companies com")
    filters = paste("pup.people_id = issues.submitted_by
                    AND pup.upeople_id = upc.upeople_id
                    AND upc.company_id = com.id
                    AND submitted_on >= upc.init
                    AND submitted_on < upc.end
                    AND com.name = ",company_name)
    if (evol) {
        q = GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
                startdate, enddate)
    } else {
        fields = paste(fields,
                       ",DATE_FORMAT (min(submitted_on),'%Y-%m-%d') as first_date,
                        DATE_FORMAT (max(submitted_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('submitted_on', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)
}
    

GetCompanyEvolOpened <- function(company_name, period, startdate, enddate, identities_db){    
    q <- GetCompanyOpened (company_name, period, startdate, enddate, identities_db, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}


GetCompanyStaticITS <- function (company_name, closed_condition, startdate, 
        enddate, identities_db) {
    
    period = ''
    q <- GetCompanyOpened (company_name, period, startdate, enddate, identities_db, FALSE)
    query <- new ("Query", sql = q)
    data0 <- run(query)

    q <- GetCompanyClosed (company_name, closed_condition, period, startdate, 
            enddate, identities_db, FALSE)
    
    query <- new ("Query", sql = q)
    data1 <- run(query)

    q <- GetCompanyChanged (company_name, period, startdate, 
            enddate, identities_db, FALSE)
    
    query <- new ("Query", sql = q)
    data2 <- run(query)

    q <- paste ("SELECT count(distinct(tracker_id)) as trackers
                 FROM issues,
                      changes,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE issues.id = changes.issue_id
                       AND pup.people_id = changes.changed_by
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND changed_on >= ",startdate," AND changed_on < ",enddate,"
                       AND changed_on >= upc.init
                       AND changed_on < upc.end")
    query <- new ("Query", sql = q)
    data3 <- run(query)
  
    
    agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data3)
    return(agg_data)
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



# COUNTRIES

GetCountriesNamesITS <- function (identities_db,startdate, enddate, filter=c()) {
    countries_limit = 30
    
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " cou.name<>'",aff,"' and ",sep="")
    }

    tables = GetTablesCountriesITS(identities_db)
    tables = paste(tables,",",identities_db,".countries cou")
    
    
    q <- paste("SELECT count(c.id) as closed, cou.name as name
                FROM ", tables,"
                WHERE ", GetFiltersCountriesITS()," AND
                   ", closed_condition, "
                   AND upc.country_id = cou.id
                   AND changed_on >= ",startdate," AND changed_on < ",enddate,"
                GROUP BY cou.name order by closed desc limit ", countries_limit, sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)             
}

GetCountriesITS <- function(identities_db, country, period, startdate, enddate, evol) {
    
    fields = "COUNT(c.id) AS closed,
              COUNT(DISTINCT(c.changed_by)) as closers"
    tables = GetTablesCountriesITS(identities_db)
    tables = paste(tables,",",identities_db,".countries cou")
          
    filters = paste(GetFiltersCountriesITS()," AND ", closed_condition, "
            AND upc.country_id = cou.id
            AND changed_on >= ",startdate," AND changed_on < ",enddate," AND
            cou.name = '", country,"' ", sep='')

    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(changed_on),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(changed_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    }
    return (q)
}

GetCountriesEvolITS <- function(identities_db, country, period, startdate, enddate) {
    q <- GetCountriesITS(identities_db, country, period, startdate, enddate, TRUE)    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCountriesStaticITS <- function(identities_db, country, startdate, enddate) {
    q <- GetCountriesITS(identities_db, country, period, startdate, enddate, FALSE)      
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

#
# People
# 

# TODO: It is the same than SCM because unique identites
GetPeopleListITS <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as pid, count(c.id) as total"
    tables = GetTablesOwnUniqueIdsITS()
    filters = GetFiltersOwnUniqueIdsITS()
    filters = paste(filters,"GROUP BY pid ORDER BY total desc")
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)        
}

GetPeopleQueryITS <- function(developer_id, period, startdate, enddate, evol) {    
    fields = "COUNT(c.id) AS closed"
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(), "AND pup.upeople_id = ", developer_id)
    
    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
                            startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(changed_on),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(changed_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
                            startdate, enddate)
    }
    return (q)
}


GetPeopleEvolITS <- function(developer_id, period, startdate, enddate) {
    q <- GetPeopleQueryITS(developer_id, period, startdate, enddate, TRUE)    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetPeopleStaticITS <- function(developer_id, startdate, enddate) {
    q <- GetPeopleQueryITS(developer_id, period, startdate, enddate, FALSE)      
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}
    


#
# EXPERIMENTAL ZONE
#

#
# Identities tool
#

its_people <- function() {
    q <- paste ("select id,name,email,user_id from people")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


#
# SCR: Gerrit support
#

# evol_opened but with an extra condition to filter strange cases in OpenStack gerrit
evol_opened_gerrit <- function (period, startdate, enddate) {
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                    COUNT(submitted_by) AS opened,
                    COUNT(DISTINCT(pup.upeople_id)) AS openers
                                    FROM issues, issues_ext_gerrit,
                    people_upeople pup
                                    WHERE pup.people_id = issues.submitted_by AND
                    issues.id = issues_ext_gerrit.issue_id AND submitted_on<mod_date
                    AND submitted_on >= ",startdate," AND submitted_on < ",enddate,"
                                    GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

evol_closed_gerrit <- function (period, startdate, enddate) {
    q <- paste("SELECT ((to_days(mod_date) - to_days(",startdate,")) div ",period,") as id,
                    COUNT(submitted_by) AS closed,
                    COUNT(DISTINCT(pup.upeople_id)) AS closers
                                    FROM issues, issues_ext_gerrit,
                    people_upeople pup
                                    WHERE pup.people_id = issues.submitted_by AND
                    issues.id = issues_ext_gerrit.issue_id AND submitted_on<mod_date
                    AND mod_date >= ",startdate," AND mod_date < ",enddate,"
                    AND (status='MERGED' or status='ABANDONED')
                                    GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


MarkovChain<-function()
{
    q<-paste("select distinct(new_value) as value
              from changes 
              where field like '%status%'")
 
    query <- new ("Query", sql = q)
    status <- run(query)  

    T<-status[order(status$value),]
    T1<-gsub("'", "", T)

    new_value<-function(old)
    {        
        q<-paste("select old_value, new_value, count(*) as issue
                  from changes 
                  where field like '%status%'
                  and old_value like '%", old , "%' 
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
                        i<-i+1 }

   	     else{  
            		c<-data.frame(old_value=0,new_value=T1[i],issue=0,f=0)
            		x<-rbind(x,c)
            		i<-i+1}

   		}


        good<-x[order(x$new_value),]

        return(good)

     }

  j<-0
  all<-c()

  for( j in 1:length(T1))
  	{  v<-new_value(T1[j])
    	   good<-v[order(v$new_value),]
     	   g<-good$f
           all<-c(all,g)
           j<-j+1
         }

  MARKOV<-matrix(all,ncol=12,nrow=12,byrow=TRUE)
  colnames(MARKOV)<-v$new_value
  rownames(MARKOV)<-v$new_value

  return(MARKOV)

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

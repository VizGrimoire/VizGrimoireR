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
## SCR.R
##
## Queries for source code review data analysis
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo San Felix <acs@bitergia.com>


##########
# Specific FROM and WHERE clauses per type of report
##########
GetSQLRepositoriesFromSCR <- function(){
    #tables necessaries for repositories
    return (" , trackers t")
}

GetSQLRepositoriesWhereSCR <- function(repository){
    #fields necessaries to match info among tables
    return (paste(" and t.url ='", repository, "'
                   and t.id = i.tracker_id", sep=""))
}

GetSQLCompaniesFromSCR <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , people_upeople pup,
                  ",identities_db,".upeople_companies upc,
                  ",identities_db,".companies c", sep=""))
}

GetSQLCompaniesWhereSCR <- function(company){
    #fields necessaries to match info among tables
    return (paste("and i.submitted_by = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and i.submitted_on >= upc.init
                  and i.submitted_on < upc.end
                  and upc.company_id = c.id
                  and c.name ='", company,"'", sep=""))
}

GetSQLCountriesFromSCR <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , people_upeople pup,
                  ",identities_db,".upeople_countries upc,
                  ",identities_db,".countries c ", sep=""))
}

GetSQLCountriesWhereSCR <- function(country){
    #fields necessaries to match info among tables
    return (paste("and i.submitted_by = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and upc.country_id = c.id
                  and c.name ='", country,"'", sep=""))
}

##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

GetSQLReportFromSCR <- function(identities_db, type_analysis){
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetSQLRepositoriesFromSCR()),
                ifelse (analysis == 'company', paste(from, GetSQLCompaniesFromSCR(identities_db)),
                ifelse (analysis == 'country', paste(from, GetSQLCountriesFromSCR(identities_db)),
                NA)))
    }
    return (from)
}


GetSQLReportWhereSCR <- function(type_analysis){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)){
        where <- ifelse (analysis == 'repository', paste(where, GetSQLRepositoriesWhereSCR(value)),
                ifelse (analysis == 'company', paste(where, GetSQLCompaniesWhereSCR(value)),
                ifelse (analysis == 'country', paste(where, GetSQLCountriesWhereSCR(value)),
                NA)))
    }
    return (where)
}

#########
# General functions
#########

GetReposSCRName <- function (startdate, enddate, limit = 0){
    limit_sql=""
    if (limit > 0) {
        limit_sql = paste(" LIMIT ", limit)
    }
    q = paste("SELECT t.url as name, COUNT(DISTINCT(i.id)) AS issues
               FROM  issues i, trackers t
               WHERE i.tracker_id = t.id AND
                 i.submitted_on >=",  startdate, " AND
                 i.submitted_on < ", enddate, "
               GROUP BY t.url
               ORDER BY issues DESC ",limit_sql,";", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetCompaniesSCRName <- function (startdate, enddate, identities_db, limit = 0){
    limit_sql=""
    if (limit > 0) {
        limit_sql = paste(" LIMIT ", limit)
    }    
    q = paste("SELECT c.name as name, COUNT(DISTINCT(i.id)) AS issues
               FROM  ",identities_db,".companies c,
                     ",identities_db,".upeople_companies upc,
                     people_upeople pup,
                     issues i
               WHERE i.submitted_by = pup.people_id AND
                 upc.upeople_id = pup.upeople_id AND
                 c.id = upc.company_id AND
                 i.status = 'merged' AND
                 i.submitted_on >=",  startdate, " AND
                 i.submitted_on < ", enddate, "
               GROUP BY c.name
               ORDER BY issues DESC ",limit_sql,";", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

#########
#Functions about the status of the review
#########

# REVIEWS
GetReviews <- function(period, startdate, enddate, type, type_analysis, evolutionary, identities_db){

    #Building the query
    fields = paste(" count(distinct(i.issue)) as ", type)
    tables = paste("issues i", GetSQLReportFromSCR(identities_db, type_analysis))
    filters <- ifelse(type == "submitted", "",
              ifelse(type == "opened", " (i.status = 'NEW' or i.status = 'WORKINPROGRESS') ",
              ifelse(type == "new", " i.status = 'NEW' ",
              ifelse(type == "inprogress", " i.status = 'WORKINGPROGRESS' ",
              ifelse(type == "closed", " (i.status = 'MERGED' or i.status = 'ABANDONED') ",
              ifelse(type == "merged", " i.status = 'MERGED' ",
              ifelse(type == "abandoned", " i.status = 'ABANDONED' ",
              NA)))))))
    filters = paste(filters, GetSQLReportWhereSCR(type_analysis), sep="")

    #Adding dates filters (and evolutionary or static analysis)
    if (evolutionary){
        q <- GetSQLPeriod(period, "i.submitted_on", fields, tables, filters,
                      startdate, enddate)
    } else{
        q = GetSQLGlobal(" i.submitted_on ", fields, tables, filters, startdate, enddate)
    }

    #Retrieving results
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

# EVOLUTIONARY META FUNCTIONS BASED ON REVIEWS

EvolReviewsSubmitted <- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, TRUE, identities_db))
}

EvolReviewsOpened <- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, TRUE, identities_db))
}

EvolReviewsNew<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "new", type_analysis, TRUE, identities_db))
}

EvolReviewsInProgress<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, TRUE, identities_db))
}

EvolReviewsClosed<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, TRUE, identities_db))
}

EvolReviewsMerged<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, TRUE, identities_db))
}
EvolReviewsAbandoned<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, TRUE, identities_db))
}

# STATIC META FUNCTIONS BASED ON REVIEWS

StaticReviewsSubmitted <- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, FALSE, identities_db))
}

StaticReviewsOpened <- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, FALSE, identities_db))
}

StaticReviewsNew<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "new", type_analysis, FALSE, identities_db))
}

StaticReviewsInProgress<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, FALSE, identities_db))
}

StaticReviewsClosed<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, FALSE, identities_db))
}

StaticReviewsMerged<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, FALSE, identities_db))
}

StaticReviewsAbandoned<- function(period, startdate, enddate, type_analysis = list(NA, NA), identities_db=NA){
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, FALSE, identities_db))
}

#WORK ON PATCHES: ANY REVIEW MAY HAVE MORE THAN ONE PATCH
GetEvaluations <- function(period, startdate, enddate, type, type_analysis, evolutionary){
    # verified - VRIF
    # approved - APRV
    # code review - CRVW
    # submitted - SUBM

    #Building the query
    fields = paste (" count(distinct(c.id)) as ", type)
    tables = paste(" changes c, issues i ", GetSQLReportFromSCR(NA, type_analysis))
    filters <- ifelse( type == 'verified', " c.field = 'VRIF' ",
               ifelse( type == 'approved', " c.field = 'APRV' ",
               ifelse( type == 'codereview', " c.field = 'CRVW' ",
               ifelse( type == 'sent', " c.field = 'SUBM' ",
               NA))))
    filters = paste(filters, " and i.id = c.issue_id ")
    filters = paste(filters, GetSQLReportWhereSCR(type_analysis))

    #Adding dates filters
    if (evolutionary){
        q <- GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                          startdate, enddate)
    }else{
        q <- GetSQLGlobal(" c.changed_on", fields, tables, filters,
                      startdate, enddate)
    }

    #Running query
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

# EVOLUTIONARY METRICS
EvolPatchesVerified <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "verified", type_analysis, TRUE))
}

EvolPatchesApproved <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "approved", type_analysis, TRUE))
}

EvolPatchesCodeReview <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "codereview", type_analysis, TRUE))
}

EvolPatchesSent <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "sent", type_analysis, TRUE))
}

#STATIC METRICS
StaticPatchesVerified  <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "verified", type_analysis, FALSE))
}

StaticPatchesApproved <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "approved", type_analysis, FALSE))
}

StaticPatchesCodeReview <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "codereview", type_analysis, FALSE))
}

StaticPatchesSent <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetEvaluations (period, startdate, enddate, "sent", type_analysis, FALSE))
}

#PATCHES WAITING FOR REVIEW FROM REVIEWER
GetWaiting4Reviewer <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

     fields = " count(distinct(c.id)) as WaitingForReviewer "
     tables = " changes c, 
                issues i,
                      (select c.issue_id as issue_id, 
                              c.old_value as old_value, 
                              max(c.id) as id 
                       from changes c, 
                            issues i 
                       where c.issue_id = i.id and 
                             i.status='NEW' 
                       group by c.issue_id, c.old_value) t1 "
     tables = paste(tables, GetSQLReportFromSCR(identities_db, type_analysis))
     filters =  " i.id = c.issue_id
                  and t1.id = c.id   
                  and (c.field='CRVW' or c.field='VRIF')
                  and (c.new_value=1 or c.new_value=2) "
     filters = paste(filters, GetSQLReportWhereSCR(type_analysis))

     if (evolutionary){
         q <- GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                           startdate, enddate)
     }else{
         q <- GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                           startdate, enddate)
     }

     query <- new("Query", sql = q)
     data <- run(query)
     return (data)
}

EvolWaiting4Reviewer <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetWaiting4Reviewer(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticWaiting4Reviewer <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetWaiting4Reviewer(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



GetWaiting4Submitter <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

     fields = "count(distinct(c.id)) as WaitingForSubmitter "
     tables = "  changes c, 
                 issues i,
                      (select c.issue_id as issue_id, 
                              c.old_value as old_value, 
                              max(c.id) as id 
                       from changes c, 
                            issues i 
                       where c.issue_id = i.id and 
                             i.status='NEW' 
                       group by c.issue_id, c.old_value) t1 "
     tables = paste(tables, GetSQLReportFromSCR(identities_db, type_analysis))
     filters = " i.id = c.issue_id
                 and t1.id = c.id  
                 and (c.field='CRVW' or c.field='VRIF') 
                 and (c.new_value=-1 or c.new_value=-2) "
     filters = paste(filters, GetSQLReportWhereSCR(type_analysis))

     if (evolutionary){
         q <- GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                           startdate, enddate)
     }else{
         q <- GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                           startdate, enddate)
     }

     query <- new("Query", sql = q)
     data <- run(query)
     return (data)
}

EvolWaiting4Submitter <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetWaiting4Submitter(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticWaiting4Submitter <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetWaiting4Submitter(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


#REVIEWERS


GetReviewers <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # TODO: so far without unique identities

    fields = paste(" count(distinct(changed_by)) as reviewers ")
    tables = " changes c "
    filters <- ""

    if (evolutionary){
        q <- GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                          startdate, enddate)
    }else{
        q <- GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                          startdate, enddate)
    }

    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolReviewers <- function (period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetReviewers(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticReviewers <- function (period, startdate, enddate, identities_db = NA, type_analysis = list(NA, NA)){
    return (GetReviewers(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetLongestReviews <- function (startdate, enddate, type_analysis = list(NA, NA)){

    q <- "select i.issue as review,
                 t1.old_value as patch, 
                 timestampdiff (HOUR, t1.min_time, t1.max_time) as timeOpened 
          from (
                select c.issue_id as issue_id, 
                       c.old_value as old_value, 
                       min(c.changed_on) as min_time, 
                       max(c.changed_on) as max_time 
                from changes c, 
                     issues i 
                where c.issue_id = i.id and 
                      i.status='NEW'  
                group by c.issue_id, 
                         c.old_value) t1,
               issues i
          where t1.issue_id = i.id
          order by timeOpened desc
          limit 20;"
    fields = paste(" i.issue as review, ", 
                   " t1.old_value as patch, ",
                   " timestampdiff (HOUR, t1.min_time, t1.max_time) as timeOpened, ")
    tables = " issues i,
               (select c.issue_id as issue_id, 
                       c.old_value as old_value, 
                       min(c.changed_on) as min_time, 
                       max(c.changed_on) as max_time 
                from changes c, 
                     issues i 
                where c.issue_id = i.id and 
                      i.status='NEW'  
                group by c.issue_id, 
                         c.old_value) t1 "
    tables = paste(tables, GetSQLReportFromSCR(identities_db, type_analysis))
    filters = " t1.issue_id = i.id "
    filters = paste(filters, GetSQLReportWhereSCR(type_analysis))

    q <- GetSQLGlobal(" i.submitted_on ", fields, tables, filters,
                           startdate, enddate)

    query <- new("Query", sql = q)
    data <- run(query)
    return (data)

}

##
# Tops
##

# Is this right???
GetTopReviewersSCR   <- function(days = 0, startdate, enddate, identities_db, bots) {
    date_limit = ""
    filter_bots = ''
    for (bot in bots){
        filter_bots <- paste(filter_bots, " up.identifier<>'",bot,"' and ",sep="")
    }


    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    
    q <- paste("SELECT up.id as id, up.identifier as reviewers,
                       count(distinct(c.id)) as reviewed
                FROM people_upeople pup, changes c, ", identities_db,".upeople up
                WHERE ", filter_bots, "
                    c.changed_by = pup.people_id and
                    pup.upeople_id = up.id and
                    c.changed_on >= ", startdate, " and
                    c.changed_on < ", enddate, "
                    ",date_limit, "
                GROUP BY up.identifier
                ORDER BY reviewed desc
                LIMIT 10;", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTopSubmittersQuerySCR   <- function(days = 0, startdate, enddate, identities_db, bots, merged = FALSE, limit = 10) {
    date_limit = ""
    merged_sql = ""
    rol = "openers"
    action = "opened"
    filter_bots = ''
    for (bot in bots){
        filter_bots <- paste(filter_bots, " up.identifier<>'",bot,"' and ",sep="")
    }

    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(submitted_on) from issues limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, submitted_on)<",days)
    }

    if (merged) {
        merged_sql = " AND status='MERGED' "
        rol = "mergers"
        action = "merged"
    }
        
    q <- paste("SELECT up.id as id, up.identifier as ",rol,",
                    count(distinct(i.id)) as ",action,"
                FROM people_upeople pup, issues i, ", identities_db,".upeople up
                WHERE ", filter_bots, "
                    i.submitted_by = pup.people_id and
                    pup.upeople_id = up.id and
                    i.submitted_on >= ", startdate, " and
                    i.submitted_on < ", enddate, "
                    ",date_limit, merged_sql, "
                GROUP BY up.identifier
                ORDER BY ",action," desc
                LIMIT ",limit, sep="")
    return(q)
}

GetTopOpenersSCR <- function(days = 0, startdate, enddate, identities_db, bots) {
    q <- GetTopSubmittersQuerySCR (days, startdate, enddate, identities_db, bots)
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTopMergersSCR   <- function(days = 0, startdate, enddate, identities_db, bots, limit = 10) {
    q <- GetTopSubmittersQuerySCR (days, startdate, enddate, identities_db, bots, TRUE, limit)
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#########
# PEOPLE: Pretty similar to ITS
#########
GetTablesOwnUniqueIdsSCR <- function(table='') {
    tables = 'changes c, people_upeople pup'
    if (table == "issues") tables = 'issues i, people_upeople pup'
    return (tables)
}

GetFiltersOwnUniqueIdsSCR <- function (table='') {
    filters = 'pup.people_id = c.changed_by'
    if (table == "issues") filters = 'pup.people_id = i.submitted_by'
    return (filters)
}

GetPeopleListSCR <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id, count(c.id) as total"
    tables = GetTablesOwnUniqueIdsSCR()
    filters = GetFiltersOwnUniqueIdsSCR()
    filters = paste(filters,"GROUP BY id ORDER BY total desc")
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

GetPeopleQuerySCR <- function(developer_id, period, startdate, enddate, evol) {
    fields = "COUNT(c.id) AS closed"
    tables = GetTablesOwnUniqueIdsSCR()
    filters = paste(GetFiltersOwnUniqueIdsSCR(), "AND pup.upeople_id = ", developer_id)

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


GetPeopleEvolSCR <- function(developer_id, period, startdate, enddate) {
    q <- GetPeopleQuerySCR(developer_id, period, startdate, enddate, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetPeopleStaticSCR <- function(developer_id, startdate, enddate) {
    q <- GetPeopleQuerySCR(developer_id, period, startdate, enddate, FALSE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

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


##########
# Specific FROM and WHERE clauses per type of report
##########
GetSQLRepositoriesFrom <- function(){
    #tables necessaries for repositories
    return (" , trackers t")
}

GetSQLRepositoriesWhere <- function(repository){
    #fields necessaries to match info among tables
    return (paste(" and t.url =", repository, " 
                   and t.id = i.tracker_id", sep=""))
}

GetSQLCompaniesFrom <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , ",identities_db,".people_upeople pup,
                  ",identities_db,".upeople_companies upc,
                  ",identities_db,".companies c", sep=""))
}

GetSQLCompaniesWhere <- function(company){
    #fields necessaries to match info among tables
    return (paste("and i.submitted_by = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and i.submitted_on >= upc.init
                  and i.submitted_on < upc.end
                  and upc.company_id = c.id
                  and c.name =", company, sep=""))
}

GetSQLCountriesFrom <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , ",identities_db,".people_upeople pup,
                  ",identities_db,".upeople_countries upc,
                  ",identities_db,".countries c ", sep=""))
}

GetSQLCountriesWhere <- function(country){
    #fields necessaries to match info among tables
    return (paste("and i.submitted_by = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and upc.country_id = c.id
                  and c.name =", country, sep=""))
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
# General functions
#########

GetReposSRCName <- function (startdate, enddate){

    q = paste("select t.url as name, 
                count(distinct(i.id)) as issues
         from  issues i,
               trackers t
         where i.tracker_id = t.id and
               i.submitted_on >=",  startdate, " and
               i.submitted_on < ", enddate, "
         group by t.url
         order by issues desc;", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


#########
#Functions about the status of the review
#########

# REVIEWS
GetReviews <- function(period, startdate, enddate, type, type_analysis, evolutionary){

    #Building the query
    fields = paste(" count(distinct(i.issue)) as ", type)
    tables = paste("issues i", GetSQLReportFrom(NA, type_analysis))
    filters <- ifelse(type == "submitted", "",
              ifelse(type == "opened", " (i.status = 'NEW' or i.status = 'WORKINPROGRESS') ",
              ifelse(type == "new", " i.status = 'NEW' ",
              ifelse(type == "inprogress", " i.status = 'WORKINGPROGRESS' ",
              ifelse(type == "closed", " (i.status = 'MERGED' or i.status = 'ABANDONED') ",
              ifelse(type == "merged", " i.status = 'MERGED' ",
              ifelse(type == "abandoned", " i.status = 'ABANDONED' ",
              NA)))))))
    filters = paste(filters, GetSQLReportWhere(type_analysis), sep="")
    print(filters)

    #Adding dates filters (and evolutionary or static analysis)
    if (evolutionary){
        q <- GetSQLPeriod(period, "i.submitted_on", fields, tables, filters,
                      startdate, enddate)
    }else{
        q = GetSQLGlobal(" i.submitted_on ", fields, tables, filters, startdate, enddate)
    }

    #Retrieving results
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

# EVOLUTIONARY META FUNCTIONS BASED ON REVIEWS

EvolReviewsSubmitted <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, TRUE))
}

EvolReviewsOpened <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, TRUE))
}

EvolReviewsNew<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "new", type_analysis, TRUE))
}

EvolReviewsInProgress<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, TRUE))
}

EvolReviewsClosed<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, TRUE))
}

EvolReviewsMerged<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, TRUE))
}
EvolReviewsAbandoned<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, TRUE))
}

# STATIC META FUNCTIONS BASED ON REVIEWS

StaticReviewsSubmitted <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, FALSE))
}

StaticReviewsOpened <- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, FALSE))
}

StaticReviewsNew<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "new", type_analysis, FALSE))
}

StaticReviewsInProgress<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, FALSE))
}

StaticReviewsClosed<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, FALSE))
}

StaticReviewsMerged<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, FALSE))
}

StaticReviewsAbandoned<- function(period, startdate, enddate, type_analysis = list(NA, NA)){
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, FALSE))
}

#WORK ON PATCHES: ANY REVIEW MAY HAVE MORE THAN ONE PATCH
GetEvaluations <- function(period, startdate, enddate, type, type_analysis, evolutionary){
    # verified - VRIF
    # approved - APRV
    # code review - CRVW
    # submitted - SUBM

    #Building the query
    fields = paste (" count(distinct(c.id)) as ", type)
    tables = paste(" changes c, issues i ", GetSQLReportFrom(NA, type_analysis))
    filters <- ifelse( type == 'verified', " c.field = 'VRIF' ",
               ifelse( type == 'approved', " c.field = 'APRV' ",
               ifelse( type == 'codereview', " c.field = 'CRVW' ",
               ifelse( type == 'sent', " c.field = 'SUBM' ",
               NA))))
    filters = paste(filters, " and i.id = c.issue_id ")
    filters = paste(filters, GetSQLReportWhere(type_analysis))

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
     tables = paste(tables, GetSQLReportFrom(identities_db, type_analysis))
     filters =  " i.id = c.issue_id
                  and t1.id = c.id   
                  and (c.field='CRVW' or c.field='VRIF')
                  and (c.new_value=1 or c.new_value=2) "
     filters = paste(filters, GetSQLReportWhere(type_analysis))

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
     tables = paste(tables, GetSQLReportFrom(identities_db, type_analysis))
     filters = " i.id = c.issue_id
                 and t1.id = c.id  
                 and (c.field='CRVW' or c.field='VRIF') 
                 and (c.new_value=-1 or c.new_value=-2) "
     filters = paste(filters, GetSQLReportWhere(type_analysis))

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
    return (GetWaiting4Reviewer(period, startdate, enddate, identities_db, type_analysis, FALSE))
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


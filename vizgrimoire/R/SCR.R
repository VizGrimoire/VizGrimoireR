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
    return (" , repositories r")
}

GetSQLRepositoriesWhere <- function(repository){
    #fields necessaries to match info among tables
    return (paste(" and r.name =", repository, " 
                   and r.id = s.repository_id", sep=""))
}

GetSQLCompaniesFrom <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , ",identities_db,".people_upeople pup,
                  ",identities_db,".upeople_companies upc,
                  ",identities_db,".companies c", sep=""))
}

GetSQLCompaniesWhere <- function(company, role){
    #fields necessaries to match info among tables
    return (paste("and s.",role,"_id = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and s.date >= upc.init
                  and s.date < upc.end
                  and upc.company_id = c.id
                  and c.name =", company, sep=""))
}

GetSQLCountriesFrom <- function(identities_db){
    #tables necessaries for companies
    return (paste(" , ",identities_db,".people_upeople pup,
                  ",identities_db,".upeople_countries upc,
                  ",identities_db,".countries c", sep=""))
}

GetSQLCountriesWhere <- function(country, role){
    #fields necessaries to match info among tables
    return (paste("and s.",role,"_id = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and upc.country_id = c.id
                  and c.name =", country, sep=""))
}

##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

GetSQLReportFrom <- function(identities_db, type = list(NA, NA)){
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type[1]
    value = [2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetSQLRepositoriesFrom()),
                ifelse (analysis == 'company', paste(from, GetSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', paste(from, GetSQLCountriesFrom(identities_db)),
                NA)))

    return (from)
}


GetSQLReportWhere <- function(type = list(NA, NA), role){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type[1]
    value = type[2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(from, GetSQLCompaniesFrom(value, role)),
                ifelse (analysis == 'country', paste(from, GetSQLCountriesFrom(value, role)),
                NA)))

    return (where)
}

#########
#Functions about the status of the review
#########


EvolReviews <- function(period, startdate, enddate, type){

    fields = paste(" count(distinct(i.issue)) as ", type)
    tables = "issues i"
    filters <- ifelse(type == "submitted", "",
              ifelse(type == "opened", " i.status = 'NEW' or i.status = 'WORKINPROGRESS' ",
              ifelse(type == "new", " i.status = 'NEW' ",
              ifelse(type == "inprogress", " i.status = 'WORKINGPROGRESS' ",
              ifelse(type == "closed", " i.status = 'MERGED' or i.status = 'ABANDONED' ",
              ifelse(type == "merged", " i.status = 'MERGED' ",
              ifelse(type == "abandoned", " i.status = 'ABANDONED' ",
              NA)))))))
    q <- GetSQLPeriod(period, "i.submitted_on", fields, tables, filters,
                      startdate, enddate)    

    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


EvolReviewers <- function(period, startdate, enddate){
    # TODO: so far without unique identities

    fields = paste(" count(distinct(changed_by)) as reviewers ")
    tables = " changes c "
    filters <- ""

    q <- GetSQLPeriod(period, " c.changed_on ", fields, tables, filters,
                      startdate, enddate)
    data <- run(query)
    return (data)
}

EvolEvaluations <- function(period, startdate, enddate, type) {
    # verified - VRIF
    # approved - APRV
    # code review - CRVW
    # submitted - SUBM

    fields = paste (" count(distinct(c.id)) as ", type)
    tables = " changes c "
    filters <- ifelse( type == 'verified', " c.field = 'VRIF' ",
               ifelse( type == 'approved', " c.field = 'APRV' ", 
               ifelse( type == 'code review', " c.field = 'CRVW' ", 
               ifelse( type == 'submitted', " c.field = 'SUBM' ",
               NA))))
    q <- GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                      startdate, enddate)

    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


#######
#Static functions
#######

Waiting4Review <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){

     q <- paste("select count(*) 
                 from changes c, 
                      (select c.issue_id as issue_id, 
                              c.old_value as old_value, 
                              max(c.id) as id 
                       from changes c, 
                            issues i 
                       where c.issue_id = i.id and 
                             i.status='NEW' 
                       group by c.issue_id, c.old_value) t1 
                 where t1.id = c.id and 
                       (c.field='CRVW' or c.field='VRIF') and
                       (c.new_value=1 or c.new_value=2);", sep="")
     query <- new("Query", sql = q)
     data <- run(query)
     return (data)
}


Waiting4Submitter <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){

     q <- paste("select count(*) 
                 from changes c, 
                      (select c.issue_id as issue_id, 
                              c.old_value as old_value, 
                              max(c.id) as id 
                       from changes c, 
                            issues i 
                       where c.issue_id = i.id and 
                             i.status='NEW' 
                       group by c.issue_id, c.old_value) t1 
                 where t1.id = c.id and 
                       (c.field='CRVW' or c.field='VRIF') and
                       (c.new_value=-1 or c.new_value=-2);", sep="")
     query <- new("Query", sql = q)
     data <- run(query)
     return (data)
}



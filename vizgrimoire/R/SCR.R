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
## Queries for SCM data analysis
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

GetSQLReportFrom <- function(identities_db, repository, company, country){
    #generic function to generate 'from' clauses

    from = ""

    if (! is.na(repository)){
        #evolution of commits in a given repository
        from <- paste(from, GetSQLRepositoriesFrom())
    }
    else if (! is.na(company)){
        #evolution of commits in a given company
        from <- paste(from, GetSQLCompaniesFrom(identities_db))
    }
    else if (! is.na(country)){
        #evolution of commits in a given country
        from <- paste(from, GetSQLCountriesFrom(identities_db))
    }
 
    return (from)
}


GetSQLReportWhere <- function(repository, company, country, role){
    #generic function to generate 'where' clauses

    where = ""

    if (! is.na(repository)){
        #evolution of commits in a given repository
        where <- paste(where, GetSQLRepositoriesWhere(repository))
    }
    else if (! is.na(company)){
        #evolution of commits in a given company
        where <- paste(where, GetSQLCompaniesWhere(company, role))
    }
    else if (! is.na(country)){
        #evolution of commits in a given country
        where <- paste(where, GetSQLCountriesWhere(country, role))
    }

    return (where)
}

#########
#Functions to obtain info per type of basic piece of data
#########

#########
#Functions about the status of the review
#########

EvolSubmittedReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                group by year(submitted_on),
                      month(submitted_on)"
                , sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolOpenedReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                where status = 'NEW' or
                      status = 'WORKINPROGRESS'
                group by year(submitted_on),
                      month(submitted_on)"
                , sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolNewReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                where status = 'NEW'
                group by year(submitted_on),
                      month(submitted_on)"
                , sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolInProgressReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                where status = 'WORKINPROGRESS'
                group by year(submitted_on),
                      month(submitted_on)"
                , sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolClosedReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                where status = 'MERGED' or
                      status = 'ABANDONED'
                group by year(submitted_on),
                      month(submitted_on)", sep="")
}


EvolMergedReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                month(submitted_on),
                count(*)
                from issues
                where status = 'MERGED'
                group by year(submitted_on),
                      month(submitted_on)", sep="")
}

EvolAbandonedReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    q <- paste("select year(submitted_on), 
                       month(submitted_on),
                       count(*)
                from issues
                where status = 'ABANDONED'
                group by year(submitted_on),
                      month(submitted_on)", sep="")
}

#######
#Static functions
#######

Waiting4Review <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){

     q <- paste("", sep="")
}


Waiting4Submitter <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){

     q <- paste("", sep="")
}


EvolReviewers <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
     #To be done
}

EvolRemainingReviews <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
     #To be done
}

EvolWaitingForUpdates <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
     #To be done
}

#EvolAvgReviewTime <- function








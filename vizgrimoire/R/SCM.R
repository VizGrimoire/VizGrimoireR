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
## AuxiliarySCM.R
##
## Queries for SCM data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>


##########
# Meta-functions to automatically call metrics functions and merge them
##########

GetSCMEvolutionaryData <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){

    # 1- Retrieving information
    commits <- EvolCommits(period, startdate, enddate, i_db, type_analysis)
    authors <- EvolAuthors(period, startdate, enddate, i_db, type_analysis)
    committers <- EvolCommitters(period, startdate, enddate, i_db, type_analysis)
    files <- EvolFiles(period, startdate, enddate, i_db, type_analysis)
    lines <- EvolLines(period, startdate, enddate, i_db, type_analysis)
    branches <- EvolBranches(period, startdate, enddate, i_db, type_analysis)
    repositories <- EvolRepositories(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    evol_data = merge(commits, committers, all = TRUE)
    evol_data = merge(evol_data, authors, all = TRUE)
    evol_data = merge(evol_data, files, all = TRUE)
    evol_data = merge(evol_data, lines, all = TRUE)
    evol_data = merge(evol_data, branches, all = TRUE)
    evol_data = merge(evol_data, repositories, all = TRUE)

    return (evol_data)
}

GetSCMStaticData <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){

    # 1- Retrieving information
    static_commits <- StaticNumCommits(period, startdate, enddate, i_db, type_analysis)
    static_authors <- StaticNumAuthors(period, startdate, enddate, i_db, type_analysis)
    static_committers <- StaticNumCommitters(period, startdate, enddate, i_db, type_analysis)
    static_files <- StaticNumFiles(period, conf$startdate, enddate, i_db, type_analysis)
    static_branches <- StaticNumBranches(period, startdate, enddate, i_db, type_analysis)
    static_repositories <- StaticNumRepositories(period, startdate, enddate, i_db, type_analysis)
    static_actions <- StaticNumActions(period, startdate, enddate, i_db, type_analysis)
    static_lines <- StaticNumLines(period, conf$startdate, enddate, i_db, type_analysis)
    avg_commits_period <- StaticAvgCommitsPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_files_period <- StaticAvgFilesPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_commits_author <- StaticAvgCommitsAuthor(period, startdate, enddate, i_db, type_analysis)
    avg_authors_period <- StaticAvgAuthorPeriod(period, startdate, conf$enddate, i_db, type_analysis)
    avg_committer_period <- StaticAvgCommitterPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_files_author <- StaticAvgFilesAuthor(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    static_data = merge(static_commits, static_committers)
    static_data = merge(static_data, static_authors)
    static_data = merge(static_data, static_files)
    static_data = merge(static_data, static_branches)
    static_data = merge(static_data, static_repositories)
    static_data = merge(static_data, static_actions)
    static_data = merge(static_data, static_lines)
    static_data = merge(static_data, avg_commits_period)
    static_data = merge(static_data, avg_files_period)
    static_data = merge(static_data, avg_commits_author)
    static_data = merge(static_data, avg_files_author)

    return (static_data)
}


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


############
#Generic function to check evolutionary or static info plus 
###########

ExecuteQuery <- function(q){
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


GetSQLReportWhere <- function(type_analysis, role){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)){
        where <- ifelse (analysis == 'repository', paste(where, GetSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(where, GetSQLCompaniesWhere(value, role)),
                ifelse (analysis == 'country', paste(where, GetSQLCountriesWhere(value, role)),
                NA)))
    }
    return (where)
}

#########
#Functions to obtain info per type of basic piece of data
#########

GetCommits <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = " count(distinct(s.id)) as commits "
    tables = paste(" scmlog s ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")
    
    if (evolutionary) {
         q <- GetSQLPeriod(period," s.date ", fields, tables, filters, 
            startdate, enddate)
    } else {
         q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

#StaticNumCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
#    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, FALSE))
#}


GetAuthors <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    fields <- " count(distinct(pup.upeople_id)) AS authors "
    tables <- " scmlog s " 
    filters = GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters, 
            startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolAuthors <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumAuthors <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, FALSE))
}




GetCommitters <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary) {
    fields <- 'count(distinct(pup.upeople_id)) AS committers '
    tables <- "scmlog s "
    filters = GetSQLReportWhere(type_analysis, "committer")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1]) ){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, " ,  ",identities_db,".people_upeople pup ", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id", sep="")
    }
    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolCommitters <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumCommitters <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, FALSE))
}




GetFiles <- function (period, startdate, enddate, identities_db, type_analysis, evolutionary) {
    fields <- " count(distinct(a.file_id)) as files "
    tables <- " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolFiles <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumFiles <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, FALSE))
}





GetLines <- function (period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #Evolution of files

    # basic parts of the query
    fields <- "sum(cl.added) as added_lines, sum(cl.removed) as removed_lines"
    tables <- "scmlog s, commits_lines cl "
    filters <- "cl.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    data <- ExecuteQuery(q)
    data$negative_removed_lines <- -data$removed_lines
    return (data)
}

EvolLines <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumLines <- function (period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, FALSE))
}




GetBranches <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    #Evolution of branches

    # basic parts of the query
    fields <- "count(distinct(a.branch_id)) as branches "
    tables <- " scmlog s, actions a "
    filters <- " a.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }
    return(ExecuteQuery(q))
}

EvolBranches <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumBranches <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



GetRepositories <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # basic parts of the query
    fields <- "count(distinct(s.repository_id)) AS repositories "
    tables <- "scmlog s "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- GetSQLReportWhere(type_analysis, "author")
    
    #executing the query
    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolRepositories <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumRepositories <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



#############
#Static numbers
#############

StaticNumCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    #TODO: first_date and last_date should be in another function
    select <- "SELECT count(s.id) as commits,
               DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
               DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date "
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                     s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q <- paste(select, from, where, rest)

    return(ExecuteQuery(q))
}

GetActions <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = " count(distinct(a.id)) as actions "
    tables = " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

    
EvolActions <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumActions <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

StaticNumLines <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {

    select <- "select sum(cl.added) as added_lines,
               sum(cl.removed) as removed_lines "
    from <- " FROM scmlog s,
                   commits_lines cl "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           cl.commit_id = s.id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    return(ExecuteQuery(q))
}

GetAvgCommitsPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = paste(" count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period, sep="")
    tables = " scmlog s "
    filters = ""

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"), sep="")

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

#EvolAvgCommitsPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
#WARNING: This function should provide same information as EvolCommits, do not use this.
#    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgCommitsPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgFilesPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = paste(" count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period, sep="")
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"), sep="")

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
                          startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                          startdate, enddate)
    }

    return(ExecuteQuery(q))
}

#EvolAvgFilesPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same info as EvolFiles, do not use this
#    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgFilesPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgCommitsAuthor <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = " count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author "
    tables = " scmlog s "
    filters = ""

    filters = GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
            startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolAvgCommitsAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticAvgCommitsAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgAuthorPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = paste(" count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period, sep="") 
    tables = " scmlog s "
    filters = ""

    filters = GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
            startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

#EvolAvgAuthorPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same information as EvolAuthors, do not use this
#    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgAuthorPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

GetAvgCommitterPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){

    fields = paste(" count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period, sep="")
    tables = " scmlog s "
    filters = ""

    filters = GetSQLReportWhere(type_analysis, "committer")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
            startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

#EvolAvgCommitterPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same info as EvolCommitters, do not use this
#    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgCommitterPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgFilesAuthor <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    
    fields = " count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author "
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    filters = paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) {
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id", sep="")
    }

    if (type_analysis[1] == "repository"){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id ", sep="")
    }

    if (evolutionary) {
        q <- GetSQLPeriod(period, " s.date ", fields, tables, filters,
            startdate, enddate)
    } else {
        q <- GetSQLGlobal(" s.date ", fields, tables, filters,
                           startdate, enddate)
    }

    return(ExecuteQuery(q))
}

EvolAvgFilesAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


StaticAvgFilesAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



StaticURL <- function() {
    q <- paste("select uri as url,type from repositories limit 1")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)    
}

#
# People
#

GetTablesOwnUniqueIdsSCM <- function() {
    return ('scmlog s, people_upeople pup')
}

GetFiltersOwnUniqueIdsSCM <- function () {
    return ('pup.people_id = s.author_id') 
}

GetPeopleListSCM <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id"
    tables = GetTablesOwnUniqueIdsSCM()
    filters = GetFiltersOwnUniqueIdsSCM()
    q = GetSQLGlobal('s.date',fields,tables, filters, startdate, enddate)        
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)        
}

GetPeopleQuerySCM <- function(developer_id, period, startdate, enddate, evol) {
    fields ='COUNT(s.id) AS commits'
    tables = GetTablesOwnUniqueIdsSCM()
    filters = GetFiltersOwnUniqueIdsSCM()
    filters = paste(filters,"AND pup.upeople_id=",developer_id)
    if (evol) {
        q = GetSQLPeriod(period,'s.date', fields, tables, filters, 
                startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(s.date),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(s.date),'%Y-%m-%d') as last_date")        
        q = GetSQLGlobal('s.date', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)            
}

GetEvolPeopleSCM <- function(developer_id, period, startdate, enddate) {
    q <- GetPeopleQuerySCM (developer_id, period, startdate, enddate, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticPeopleSCM <- function(developer_id, startdate, enddate) {
    q <- GetPeopleQuerySCM (developer_id, NA, startdate, enddate, FALSE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)        
}

# 
# Legacy and non legacy code - Cleanup
#

EvolCompanies <- function(period, startdate, enddate){	

    fields = "count(distinct(upc.company_id)) as companies"
    tables = " scmlog s, people_upeople pup, upeople_companies upc"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upc.upeople_id and
               s.date >= upc.init and 
               s.date < upc.end"
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
                           startdate, enddate)
    query <- new("Query", sql = q)
	companies<- run(query)
	return(companies)
}

EvolCountries <- function(period, startdate, enddate){	

    fields = "count(distinct(upc.country_id)) as countries"
    tables = "scmlog s, people_upeople pup, upeople_countries upc"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upc.upeople_id"
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
               startdate, enddate)      
    query <- new("Query", sql = q)
	countries<- run(query)
	return(countries)
}

last_activity <- function(days) {
    #commits
    q <- paste("select count(*) as commits_",days,"
                from scmlog 
                where date >= (
                      select (max(date) - INTERVAL ",days," day) 
                      from scmlog)", sep="");
    query <- new("Query", sql = q)
    data1 = run(query)

    #authors
    q <- paste("select count(distinct(pup.upeople_id)) as authors_",days,"
                from scmlog s, 
                     people_upeople pup 
                where pup.people_id = s.author_id and 
                      s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)", sep="");
    query <- new("Query", sql = q)
    data2 = run(query)


    #files
    q <- paste("select count(distinct(a.file_id)) as files_",days,"
                from scmlog s, 
                     actions a 
                where a.commit_id = s.id and 
                      s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)", sep="");
    query <- new("Query", sql = q)
    data3 = run(query)

    #added_removed lines
    q <- paste(" select sum(cl.added) as added_lines_",days,",
                        sum(cl.removed) as removed_lines_",days,"
                 from scmlog s, 
                      commits_lines cl 
                 where cl.commit_id = s.id and 
                       s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)", sep="");
    query <- new("Query", sql = q)
    data4 = run(query)

    agg_data = merge(data1, data2)
    agg_data = merge(agg_data, data3)
    agg_data = merge(agg_data, data4)

    return (agg_data)
}

top_people <- function(days, startdate, enddate, role, filters="") {

    affiliations = ""
    for (aff in filters){
        affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
    }
 
    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(date) from scmlog limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, date)<",days)
    }
    
    q <- paste("SELECT u.id as id, u.identifier as ", role, "s,
                 count(distinct(s.id)) as commits
               FROM scmlog s,
                 people_upeople pup,
                 upeople u,
                 upeople_companies upc,
                 companies c
               WHERE s.", role, "_id = pup.people_id and
                 pup.upeople_id = u.id and
                 u.id = upc.upeople_id and
                 s.date >= ", startdate, " and
                 s.date < ", enddate," ", date_limit, " and
                 s.date >= upc.init and
                 s.date < upc.end and ", affiliations, "
                 upc.company_id = c.id
               GROUP BY u.identifier
               ORDER BY commits desc
               LIMIT 10;", sep="")
    
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)	
}

top_files_modified <- function() {
      #FIXME: to be updated to use stardate and enddate values
      q <- paste("select file_name, count(commit_id) as modifications 
                  from action_files a join files f on a.file_id = f.id 
                  where action_type='M' 
                  group by f.id 
                  order by modifications desc limit 10; ")	
      query <- new("Query", sql = q)
      data <- run(query)
      return (data)	
}

## TODO: Follow top_committers implementation
top_authors <- function(startdate, enddate) {
    q <- paste("SELECT u.id as id, u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     people_upeople pup,
                     upeople u
                where s.author_id = pup.people_id and
                      pup.upeople_id = u.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, "
                group by u.identifier
                order by commits desc
                LIMIT 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}


top_authors_wo_affiliations <- function(list_affs, startdate, enddate) {
    #list_affs
    affiliations = ""
    for (aff in list_affs){
        affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
    }

    q <- paste("SELECT u.id as id, u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     people_upeople pup,
                     upeople u, 
                     upeople_companies upc,
                     companies c
                where s.author_id = pup.people_id and
                      pup.upeople_id = u.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, " and
                      ",affiliations,"
                      pup.upeople_id = upc.upeople_id and
                      upc.company_id = c.id
                group by u.identifier
                order by commits desc
                LIMIT 10;")
        query <- new("Query", sql = q)
        data <- run(query)
        return (data)
}

top_authors_year <- function(year) {
    q <- paste("SELECT u.id as id, u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     people_upeople pup,
                     upeople u
                where s.author_id = pup.people_id and
                      pup.upeople_id = u.id and
                      year(s.date) = ",year,"
                group by u.identifier
                order by commits desc
                LIMIT 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

people <- function() {
	q <- paste ("select id,identifier from upeople")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data);
}


companies_name_wo_affs <- function(affs_list, startdate, enddate) {
        #List of companies without certain affiliations
        affiliations = ""
        for (aff in affs_list){
            affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
        }    

        q <- paste ("select distinct(c.name)
                    from companies c,
                         people_upeople pup,
                         upeople_companies upc,
                         scmlog s
                    where c.id = upc.company_id and
                          upc.upeople_id = pup.upeople_id and
                          s.date >= upc.init and
                          s.date < upc.end and
                          pup.people_id = s.author_id and
                          ",affiliations," 
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    group by c.name
                    order by count(distinct(s.id)) desc;", sep="")
        query <- new("Query", sql = q)
        data <- run(query)
        return (data)
}

companies_name <- function(startdate, enddate) {
    # companies_limit = 30
    
	q <- paste ("select distinct(c.name)
                    from companies c,
                         people_upeople pup,
                         upeople_companies upc,
                         scmlog s
                    where c.id = upc.company_id and
                          upc.upeople_id = pup.upeople_id and
                          pup.people_id = s.author_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    group by c.name
                    order by count(distinct(s.id)) desc", sep="")
                    # order by count(distinct(s.id)) desc LIMIT ", companies_limit, sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}


evol_info_data_companies <- function(startdate, enddate) {
	
	q <- paste ("select count(distinct(c.id)) as companies 
                     from companies c,
                          upeople_companies upc,
                          people_upeople pup,
                          scmlog s
                     where c.id = upc.company_id and
                           upc.upeople_id = pup.upeople_id and
                           pup.people_id = s.author_id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, ";", sep="") 
	query <- new("Query", sql = q)
	data13 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2006
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date < upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2006")
	query <- new("Query", sql = q)
	data14 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2009
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date < upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2009")
	query <- new("Query", sql = q)
	data15 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2012
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date < upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2012")
	query <- new("Query", sql = q)
	data16 <- run(query)
	
	
	agg_data = merge(data13, data14)
	agg_data = merge(agg_data, data15)
	agg_data = merge(agg_data, data16)
	return (agg_data)
}

evol_info_data_countries <- function(startdate, enddate) {
	
	q <- paste ("select count(distinct(upc.country_id)) as countries
                     from upeople_countries upc,
                          people_upeople pup,
                          scmlog s
                     where upc.upeople_id = pup.upeople_id and
                           pup.people_id = s.author_id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, ";", sep="") 
	query <- new("Query", sql = q)
	data <- run(query)
        return (data)
    }

company_top_authors <- function(company_name, startdate, enddate) {
	
	q <- paste ("select u.id as id, u.identifier  as authors,
                            count(distinct(s.id)) as commits                         
                     from people p,
                          scmlog s,
                          people_upeople pup,
                          upeople u,
                          upeople_companies upc,
                          companies c
                     where  p.id = s.author_id and
                            s.author_id = pup.people_id and
                            pup.upeople_id = upc.upeople_id and 
                            pup.upeople_id = u.id and
                            s.date >= upc.init and 
                            s.date < upc.end and
                            upc.company_id = c.id and   
                            s.date >=", startdate, " and
                            s.date < ", enddate, " and
                            c.name =", company_name, "
                     group by u.id
                     order by count(distinct(s.id)) desc
                     limit 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

company_top_authors_year <- function(company_name, year){
	
	q <- paste ("select u.id as id, u.identifier as authors,
                            count(distinct(s.id)) as commits                         
                    from people p,
                         scmlog s,
                         people_upeople pup,
                         upeople u,
                         upeople_companies upc,
                         companies c
                    where  p.id = s.author_id and
                           s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and 
                           pup.upeople_id = u.id and
                           s.date >= upc.init and 
                           s.date < upc.end and
                           year(s.date)=",year," and
                           upc.company_id = c.id and
                           c.name =", company_name, "
                    group by u.id
                    order by count(distinct(s.id)) desc
                    limit 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

evol_companies <- function(period, startdate, enddate){	
	
        q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           count(distinct(upc.company_id)) as companies
                    from   scmlog s,
                           people_upeople pup,
                           upeople_companies upc
                    where  s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and 
                           s.date < upc.end and
                           s.date >=", startdate, " and
                           s.date < ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}

repos_name <- function(startdate, enddate) {
	q <- paste ("select distinct(name)
                     from repositories r,
                          scmlog s
                     where r.id = s.repository_id and
                           s.date >", startdate, " and
                           s.date <= ", enddate, "
                     order by name;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}



# COUNTRIES support
scm_countries_names <- function(identities_db, startdate, enddate) {
   
    countries_limit = 30 
    rol = "author" #committer
    
    q <- paste("SELECT count(s.id) as commits, c.name as name 
                FROM scmlog s, 
                     people_upeople pup,
                     ",identities_db,".countries c,
                     ",identities_db,".upeople_countries upc
                WHERE pup.people_id = s.",rol,"_id AND
                      pup.upeople_id  = upc.upeople_id and
                      upc.country_id = c.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, "
                group by c.name
                order by commits desc LIMIT ", countries_limit, sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)    
}



# Companies / Countries support

scm_companies_countries_evol <- function(identities_db, company, country, period, startdate, enddate) {
    
    rol = "author" #committer
    
    q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                count(s.id) AS commits,
                COUNT(DISTINCT(s.",rol,"_id)) as ", rol,"s
                FROM scmlog s, 
                     people_upeople pup,
                     ",identities_db,".countries ct,
                     ",identities_db,".upeople_countries upct,
                     ",identities_db,".companies com,
                     ",identities_db,".upeople_companies upcom
                WHERE pup.people_id = s.",rol,"_id AND
                      pup.upeople_id  = upct.upeople_id and
                      pup.upeople_id = upcom.upeople_id AND
                      upcom.company_id = com.id AND
                      upct.country_id = ct.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, " and
                      ct.name = '", country, "' AND
                      com.name ='",company,"'
                GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

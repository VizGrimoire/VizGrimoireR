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
    # Meta function that includes basic evolutionary metrics from the source code
    # management system. Those are merged and returned.

    # 1- Retrieving information
    commits <- EvolCommits(period, startdate, enddate, i_db, type_analysis)
    authors <- EvolAuthors(period, startdate, enddate, i_db, type_analysis)
    committers <- EvolCommitters(period, startdate, enddate, i_db, type_analysis)
    files <- EvolFiles(period, startdate, enddate, i_db, type_analysis)
    lines <- EvolLines(period, startdate, enddate, i_db, type_analysis)
    branches <- EvolBranches(period, startdate, enddate, i_db, type_analysis)
    repositories <- EvolRepositories(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    evol_data = merge(commits, repositories, all = TRUE)
    
    # This workaround fixes the bug when committers or
    # authors are empty data frames. Merging an empty
    # with a non-empty frame returned a new data frame
    # with NAs.
    if (nrow(committers) > 0) {
        evol_data = merge(evol_data, committers, all = TRUE)
    }
    if (nrow(authors) > 0) {
        evol_data = merge(evol_data, authors, all = TRUE)
    }
    evol_data = merge(evol_data, files, all = TRUE)
    evol_data = merge(evol_data, lines, all = TRUE)
    evol_data = merge(evol_data, branches, all = TRUE)

    return (evol_data)
}

GetSCMStaticData <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){
    # Meta function that includes basic aggregated metrics from the source code
    # management system. Those are merged and returned.

    # 1- Retrieving information
    static_commits <- StaticNumCommits(period, startdate, enddate, i_db, type_analysis)
    static_authors <- StaticNumAuthors(period, startdate, enddate, i_db, type_analysis)
    static_committers <- StaticNumCommitters(period, startdate, enddate, i_db, type_analysis)
    static_files <- StaticNumFiles(period, startdate, enddate, i_db, type_analysis)
    static_branches <- StaticNumBranches(period, startdate, enddate, i_db, type_analysis)
    static_repositories <- StaticNumRepositories(period, startdate, enddate, i_db, type_analysis)
    static_actions <- StaticNumActions(period, startdate, enddate, i_db, type_analysis)
    static_lines <- StaticNumLines(period, startdate, enddate, i_db, type_analysis)
    avg_commits_period <- StaticAvgCommitsPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_files_period <- StaticAvgFilesPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_commits_author <- StaticAvgCommitsAuthor(period, startdate, enddate, i_db, type_analysis)
    avg_authors_period <- StaticAvgAuthorPeriod(period, startdate, enddate, i_db, type_analysis)
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

GetSQLDomainsFrom <- function(identities_db) {
    #tables necessaries for domains
    return (paste(" , ",identities_db,".people_upeople pup,
                            ",identities_db,".upeople_domains upd,
                            ",identities_db,".domains d", sep=""))
}

GetSQLDomainsWhere <- function(domain, role) {
    #fields necessaries to match info among tables
    return (paste("and s.",role,"_id = pup.people_id
                            and pup.upeople_id = upd.upeople_id
                            and upd.domain_id = d.id
                            and d.name =", domain, sep=""))
}

############
#Generic functions to check evolutionary or static info and for the execution of the final query
###########

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
                ifelse (analysis == 'domain', paste(from, GetSQLDomainsFrom(identities_db)),
                NA))))
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
                 ifelse (analysis == 'domain', paste(where, GetSQLDomainsWhere(value, role)),
                 NA))))
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


GetCommits <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count commits.
    # That query is built and results returned.

    fields = " count(distinct(s.id)) as commits "
    tables = paste(" scmlog s, actions a ", GetSQLReportFrom(identities_db, type_analysis))
    filters = paste(GetSQLReportWhere(type_analysis, "author"), " and s.id=a.commit_id ") 
    
    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # Returns the evolution of commits through the time

    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

#StaticNumCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
#    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, FALSE))
#}


GetAuthors <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count authors
    # That query is later built and executed

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolAuthors <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the evolution of authors through the time
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumAuthors <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the aggregated number of authors in the specified timeperiod (enddate - startdate)
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

GetDiffAuthorsDays <- function(period, init_date, identities_db=NA, days){
    # This function provides the percentage in activity between two periods:

    chardates = GetDates(init_date, days)
    lastauthors = StaticNumAuthors(period, chardates[2], chardates[1], identities_db)
    lastauthors = as.numeric(lastauthors[1])
    prevauthors = StaticNumAuthors(period, chardates[3], chardates[2], identities_db)
    prevauthors = as.numeric(prevauthors[1])
    diffauthorsdays = data.frame(diff_netauthors = numeric(1), percentage_authors = numeric(1))
    diffauthorsdays$diff_netauthors = lastauthors - prevauthors
    diffauthorsdays$percentage_authors = GetPercentageDiff(prevauthors, lastauthors)

    colnames(diffauthorsdays) <- c(paste("diff_netauthors","_",days, sep=""), paste("percentage_authors","_",days, sep=""))

    return (diffauthorsdays)
}


GetCommitters <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary) {
    # This function contains basic parts of the query to count committers
    # That query is later built and executed

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolCommitters <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the evolution of the number of committers through the time
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumCommitters <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the aggregate number of committers in the specified timeperiod (enddate - startdate)
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetFiles <- function (period, startdate, enddate, identities_db, type_analysis, evolutionary) {
    # This function contains basic parts of the query to count files
    # That query is later built and executed

    fields <- " count(distinct(a.file_id)) as files "
    tables <- " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolFiles <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the evolution of the number of files through the time
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumFiles <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the aggregate number of unique files in the specified timeperiod (enddate - startdate)
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

GetDiffFilesDays <- function(period, init_date, identities_db=NA, days){
    # This function provides the percentage in activity between two periods:

    chardates = GetDates(init_date, days)
    lastfiles = StaticNumFiles(period, chardates[2], chardates[1], identities_db)
    lastfiles = as.numeric(lastfiles[1])
    prevfiles = StaticNumFiles(period, chardates[3], chardates[2], identities_db)
    prevfiles = as.numeric(prevfiles[1])
    diff_files_days = data.frame(diff_netfiles = numeric(1), percentage_files = numeric(1))
    diff_files_days$diff_netfiles = lastfiles - prevfiles
    diff_files_days$percentage_files = GetPercentageDiff(prevfiles, lastfiles)

    colnames(diff_files_days) <- c(paste("diff_netfiles","_",days, sep=""), paste("percentage_files","_",days, sep=""))

    return (diff_files_days)
}


GetLines <- function (period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count lines
    # That query is later built and executed

    # basic parts of the query
    fields <- "sum(cl.added) as added_lines, sum(cl.removed) as removed_lines"
    tables <- "scmlog s, commits_lines cl "
    filters <- "cl.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    data <- ExecuteQuery(q)
    if (length(data)>0) {data$negative_removed_lines <- -data$removed_lines}
    return (data)
}

EvolLines <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    # returns the evolution of the number of lines through the time
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumLines <- function (period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the aggregate number of lines in the specified timeperiod (enddate - startdate)
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

GetDiffLinesDays <- function(period, init_date, identities_db=NA, days){
    # This function provides the percentage in activity between two periods:

    chardates = GetDates(init_date, days)
    lastlines = StaticNumLines(period, chardates[2], chardates[1], identities_db)
    last_added_lines = as.numeric(lastlines$added_lines)
    last_removed_lines = as.numeric(lastlines$removed_lines)

    prevlines = StaticNumLines(period, chardates[3], chardates[2], identities_db)
    prev_added_lines = as.numeric(prevlines$added_lines)
    prev_removed_lines = as.numeric(prevlines$removed_lines)

    diff_lines_days = data.frame(diff_netadded_lines = numeric(1), percentage_added_lines = numeric(1),
                                 diff_netremoved_lines = numeric(1), percentage_removed_lines = numeric(1))
    diff_lines_days$diff_netadded_lines = last_added_lines - prev_added_lines
    diff_lines_days$percentage_added_lines = GetPercentageDiff(prev_added_lines, last_added_lines)
    diff_lines_days$diff_netremoved_lines = last_removed_lines - prev_removed_lines
    diff_lines_days$percentage_removed_lines = GetPercentageDiff(prev_removed_lines, last_removed_lines)

    colnames(diff_lines_days) <- c(paste("diff_netadded_lines","_",days, sep=""),
                                   paste("percentage_added_lines","_",days, sep=""),
                                   paste("diff_netremoved_lines","_",days, sep=""),
                                   paste("percentage_removed_lines","_",days, sep=""))

    return (diff_lines_days)
}


GetBranches <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count branches
    # That query is later built and executed
    
    # basic parts of the query
    fields <- "count(distinct(a.branch_id)) as branches "
    tables <- " scmlog s, actions a "
    filters <- " a.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolBranches <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the evolution of the number of branches through the time
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumBranches <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    # returns the aggregate number of branches in the specified timeperiod (enddate - startdate)
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



GetRepositories <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count repositories
    # That query is later built and executed

    # basic parts of the query
    fields <- "count(distinct(s.repository_id)) AS repositories "
    tables <- "scmlog s "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- GetSQLReportWhere(type_analysis, "author")
    
    #executing the query
    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

EvolRepositories <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # returns the evolution of the number of repositories through the time
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumRepositories <- function(period, startdate, enddate, identities_db, type_analysis = list(NA, NA)){
    # returns the aggregate number of repositories in the specified timeperiod (enddate - startdate)
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


StaticNumCommits <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    # returns the aggregate number of commits in the specified timeperiod (enddate - startdate)
    # TODO: this function is deprecated, but the new one is not ready yet. This should directly call
    #       GetCommits as similarly done by EvolCommits function.

    #TODO: first_date and last_date should be in another function
    select <- "SELECT count(distinct(s.id)) as commits,
               DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
               DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date "
    from <- " FROM scmlog s, actions a " 
    where <- paste(" where s.date >=", startdate, " and
                     s.date < ", enddate, " and
                     s.id = a.commit_id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q <- paste(select, from, where, rest)

    return(ExecuteQuery(q))
}

GetDiffCommitsDays <- function(period, init_date, days){
    # This function provides the percentage in activity between two periods:
    #    Period one: enddate - days
    #    Period two: (enddate - days) - days
    # Example: Difference of activity between last 7 days of 2012 and previous 7 days
    #          Period 1: commits between 2012-12-31 and 2012-12-24
    #          Period 2: commits between 2012-12-24 and 2012-12-17
    # The netvalue indicates if this is an increment (positive value) or decrement (negative value)

    chardates = GetDates(init_date, days)
    lastcommits = StaticNumCommits(period, chardates[2], chardates[1])
    lastcommits = as.numeric(lastcommits[1])
    prevcommits = StaticNumCommits(period, chardates[3], chardates[2])
    prevcommits = as.numeric(prevcommits[1])
    diffcommitsdays = data.frame(diff_netcommits = numeric(1), percentage_commits = numeric(1))

    diffcommitsdays$diff_netcommits = lastcommits - prevcommits
    diffcommitsdays$percentage_commits = GetPercentageDiff(prevcommits, lastcommits)

    colnames(diffcommitsdays) <- c(paste("diff_netcommits","_",days, sep=""), paste("percentage_commits","_",days, sep=""))

    return (diffcommitsdays)
}


GetActions <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # This function contains basic parts of the query to count actions.
    # An action is any type of change done in a file (addition, copy, removal, etc)
    # That query is later built and executed

    fields = " count(distinct(a.id)) as actions "
    tables = " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"))

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

    
EvolActions <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the evolution of the number of actions through the time
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticNumActions <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    # returns the aggregate number of actions in the specified timeperiod (enddate - startdate)
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

StaticNumLines <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    # returns the aggregate number of repositories in the specified timeperiod (enddate - startdate)
    # TODO: this function is deprecated, this should call GetLines

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
    # returns the average number of commits per period of time (day, week, month, etc...) 
    # in the specified timeperiod (enddate - startdate)

    fields = paste(" count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period, sep="")
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"), sep="")

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))
}

#EvolAvgCommitsPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
#WARNING: This function should provide same information as EvolCommits, do not use this.
#    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgCommitsPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    # returns the average number of commits per period (weekly, monthly, etc) in the specified timeperiod (enddate - startdate)
    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgFilesPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # returns the average number of files per period (Weekly, monthly, etc) in the specified
    # time period (enddate - startdate) 
    fields = paste(" count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period, sep="")
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    tables <- paste(tables, GetSQLReportFrom(identities_db, type_analysis))
    filters <- paste(filters, GetSQLReportWhere(type_analysis, "author"), sep="")

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

#EvolAvgFilesPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same info as EvolFiles, do not use this
#    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgFilesPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the average number of files per period (Weekly, monthly, etc) in the specified
    # time period (enddate - startdate)
    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgCommitsAuthor <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # returns the average number of commits per author in the specified
    # time period (enddate - startdate)

    fields = " count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author "
    tables = " scmlog s, actions a " 
    filters = " s.id = a.commit_id " 

    filters = paste(filters, GetSQLReportWhere(type_analysis, "author"), sep="")

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))
}

EvolAvgCommitsAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the average number of commits per author in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

StaticAvgCommitsAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the average and total number of commits per author in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgAuthorPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # returns the average number of authors per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

#EvolAvgAuthorPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same information as EvolAuthors, do not use this
#    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgAuthorPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the average number of authors per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}

GetAvgCommitterPeriod <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # returns the average number of committers per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))
}

#EvolAvgCommitterPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
#WARNING: this function should return same info as EvolCommitters, do not use this
#    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#}

StaticAvgCommitterPeriod <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)){
    # returns the average number of committers per period (weekly, monthly) in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))
}


GetAvgFilesAuthor <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    # returns the average number of files per author (weekly, monthly) in the specified
    # time period (enddate - startdate)    

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

    q <- BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)


    return(ExecuteQuery(q))
}

EvolAvgFilesAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    # returns the average number of files per author and its evolution (weekly, monthly) in the specified
    # time period (enddate - startdate)  
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))
}


StaticAvgFilesAuthor <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)) {
    # returns the average number of files per author (weekly, monthly) in the specified
    # time period (enddate - startdate)  
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))
}



StaticURL <- function() {
    # Returns the SCM URL     

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
    fields = "DISTINCT(pup.upeople_id) as pid, COUNT(s.id) as total"
    tables = GetTablesOwnUniqueIdsSCM()
    filters = GetFiltersOwnUniqueIdsSCM()
    filters = paste(filters,"GROUP BY pid ORDER BY total desc, pid")
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
    # Returns the evolution in the provided period of the number of total companies

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
    # Returns the evolution in the provided period of the number of total countries

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

EvolDomains <- function(period, startdate, enddate){
    # Returns the evolution in the provided period of the number of total domains

    fields = "COUNT(DISTINCT(upd.domain_id)) AS domains"
    tables = "scmlog s, people_upeople pup, upeople_domains upd"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upd.upeople_id"
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters,
            startdate, enddate)
    query <- new("Query", sql = q)
    domains<- run(query)
    return(domains)
}

last_activity <- function(days) {
    # Given a number of days, this function calculates the number of
    # commits, authors, files, added and removed lines that took place
    # in a project. 

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

top_people <- function(days, startdate, enddate, role, filters="", limit) {
    # This function returns the top people participating in the source code.
    # Dataset can be filtered by the affiliations, where specific companies
    # can be ignored.
    # In addition, the number of days allows to limit the study to the last
    # X days specified in that parameter

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
               LIMIT " ,limit, ";", sep="")
    
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)	
}

top_files_modified <- function() {
      # Top 10 modified files

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
    # Top 10 authors without filters
    ##
    ## DEPRECATED use top_people instead
    ##

    q <- paste("SELECT u.id as id, u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     actions a,
                     people_upeople pup,
                     upeople u
                where s.id = a.commit_id and
                      s.author_id = pup.people_id and 
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
    # top ten authors with affiliation removal
    #list_affs
    affiliations = ""
    for (aff in list_affs){
        affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
    }

    q <- paste("SELECT u.id as id, u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     actions a,
                     people_upeople pup,
                     upeople u, 
                     upeople_companies upc,
                     companies c
                where s.id = a.commit_id and 
                      s.author_id = pup.people_id and 
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
   # Given a year, this functions provides the top 10 authors 
   # of such year
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
    # List of people participating in the source code development
 
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

    q <- paste ("select c.name
                 from companies c,
                      people_upeople pup,
                      upeople_companies upc,
                      scmlog s, 
                      actions a
                 where c.id = upc.company_id and
                       upc.upeople_id = pup.upeople_id and
                       s.date >= upc.init and
                       s.date < upc.end and
                       pup.people_id = s.author_id and
                       s.id = a.commit_id and
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
    
    q <- paste ("select c.name
                 from companies c,
                      people_upeople pup,
                      upeople_companies upc,
                      scmlog s, 
                      actions a
                 where c.id = upc.company_id and
                       upc.upeople_id = pup.upeople_id and
                       pup.people_id = s.author_id and
                       s.id = a.commit_id and
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
    # DEPRECATED FUNCTION; TO BE REMOVED	

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

company_top_authors <- function(company_name, startdate, enddate, limit) {
    # Returns top ten authors per company
 	
    q <- paste ("select u.id as id, u.identifier  as authors,
                        count(distinct(s.id)) as commits                         
                 from people p,
                      scmlog s,
                      actions a, 
                      people_upeople pup,
                      upeople u,
                      upeople_companies upc,
                      companies c
                 where  s.id = a.commit_id and
                        p.id = s.author_id and 
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
                 limit ",limit ,";")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

company_top_authors_year <- function(company_name, year, limit){
    # Top 10 authors per company and in a given year
	
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
                 limit ",limit,";")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

evol_companies <- function(period, startdate, enddate){	
    # Evolution of companies, also deprecated function
	
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
    # List of repositories name

    q <- paste ("select count(distinct(s.id)) as total, 
                        name
                 from actions a, 
                      scmlog s, 
                      repositories r
                 where s.id = a.commit_id and
                       s.repository_id=r.id and
                       s.date >", startdate, " and
                       s.date <= ", enddate, "
                 group by repository_id 
                 order by total desc");
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

# Domains
evol_info_data_domains <- function(startdate, enddate) {
    q <- paste ("SELECT COUNT(DISTINCT(upd.domain_id)) AS domains
                    FROM upeople_domains upd,
                    people_upeople pup,
                    scmlog s
                    WHERE upd.upeople_id = pup.upeople_id AND
                    pup.people_id = s.author_id AND
                    s.date >=", startdate, " AND
                    s.date < ", enddate, ";", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

scm_domains_names <- function(identities_db, startdate, enddate) {

    rol = "author" #committer

    q <- paste("SELECT count(s.id) as commits, d.name as name
                    FROM scmlog s,
                    people_upeople pup,
                    ",identities_db,".domains d,
                    ",identities_db,".upeople_domains upd
                    WHERE pup.people_id = s.",rol,"_id AND
                    pup.upeople_id  = upd.upeople_id and
                    upd.domain_id = d.id and
                    s.date >=", startdate, " and
                    s.date < ", enddate, "
                    GROUP BY d.name
                    ORDER BY commits desc", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

##############
# Micro Studies
##############

GetCodeCommunityStructure <- function(period, startdate, enddate, identities_db){
  # This function provides information about the general structure of the community.
  # This is divided into core, regular and ocassional authors
  # Core developers are defined as those doing up to a 80% of the total commits
  # Regular developers are defind as those doing from the 80% to a 99% of the total commits
  # Occasional developers are defined as those doing from the 99% to the 100% of the commits

  # Init of structure to be returned
  community <- numeric(0)
  community$core <- numeric(1)
  community$regular <- numeric(1)
  community$occasional <- numeric(1)

  q <- paste("select count(distinct(s.id))
                       from scmlog s, people p, actions a
                       where s.author_id = p.id and
                             p.email <> '%gerrit@%' and
                             p.email <> '%jenkins@%' and
                             s.id = a.commit_id and
                             s.date>=",startdate," and
                             s.date<=",enddate,";", sep="")
  query <- new("Query", sql=q)
  total <- run(query)
  total_commits <- as.numeric(total)

  # Database access: developer, %commits
  q <- paste(" select pup.upeople_id,
                      (count(distinct(s.id))) as commits
               from scmlog s,
                    actions a,
                    people_upeople pup,
                    people p
               where s.id = a.commit_id and
                     s.date>=",startdate," and
                     s.date<=",enddate," and
                     s.author_id = pup.people_id and
                     s.author_id = p.id and
                     p.email <> '%gerrit@%' and
                     p.email <> '%jenkins@%'
               group by pup.upeople_id
               order by commits desc; ", sep="")

  query <- new("Query", sql=q)
  people <- run(query)
  people$commits = (people$commits / total_commits) * 100

  # Calculating number of core, regular and occasional developers
  cont = 0
  core = 0
  core_f = TRUE # flag
  regular = 0
  regular_f = TRUE  # flag
  occasional = 0
  devs = 0

  for (value in people$commits){
    cont = cont + value
    devs = devs + 1

    if (core_f && cont >= 80){
      #core developers number reached
      core = devs
      core_f = FALSE
    }
    if (regular_f && cont >= 95){
      regular = devs
      regular_f = FALSE
    }

  }
  occasional = devs - regular
  regular = regular - core

  # inserting values in variable
  community$core = core
  community$regular = regular
  community$occasional = occasional

  return(community)

}


GetCommitsSummaryCompanies <- function(period, startdate, enddate, identities_db, num_companies){
    # This function returns the following dataframe structrure
    # unixtime, date, week/month/..., company1, company2, ... company[num_companies -1], others
    # The 3 first fields are used for data and ordering purposes
    # The "companyX" fields are those that provide info about that company
    # The "Others" field is the aggregated value of the rest of the companies

    companies  <- companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), startdate, enddate)
    companies <- companies$name

    first = TRUE
    first_companies = data.frame()
    count = 1
    for (company in companies){
        company_name = paste("'", company, "'", sep='')
        company_aux = paste("", company, "", sep='')

        commits = EvolCommits(period, startdate, enddate, identities_db, list("company", company_name))
        commits <- completePeriodIds(commits, conf$granularity, conf)
        commits <- commits[order(commits$id), ]
        commits[is.na(commits)] <- 0

        if (count <= num_companies -1){
            #Case of companies with entity in the dataset
            if (first){
                first = FALSE
                first_companies = commits
            }
            first_companies = merge(first_companies, commits, all=TRUE)
            colnames(first_companies)[colnames(first_companies)=="commits"] <- company_aux
        } else {

            #Case of companies that are aggregated in the field Others
            if (first==FALSE){
                first = TRUE
                first_companies$Others = commits$commits
            }else{
                first_companies$Others = first_companies$Others + commits$commits
            }
        }
        count = count + 1
    }

    #TODO: remove global variables...
    first_companies <- completePeriodIds(first_companies, conf$granularity, conf)
    first_companies <- first_companies[order(first_companies$id), ]
    first_companies[is.na(first_companies)] <- 0

    return(first_companies)
}

# Demographics
ReportDemographicsAgingSCM <- function (enddate, destdir) {
    d <- new ("Demographics","scm",6)
    people <- Aging(d)
    people$age <- as.Date(enddate) - as.Date(people$firstdate)
    people$age[people$age < 0 ] <- 0
    aux <- data.frame(people["id"], people["age"])
    new <- list()
    new[['date']] <- enddate
    new[['persons']] <- aux
    createJSON (new, paste(c(destdir, "/scm-demographics-aging.json"), collapse=''))
}

ReportDemographicsBirthSCM <- function (enddate, destdir) {
    d <- new ("Demographics","scm",6)
    newcomers <- Birth(d)
    newcomers$age <- as.Date(enddate) - as.Date(newcomers$firstdate)
    newcomers$age[newcomers$age < 0 ] <- 0
    aux <- data.frame(newcomers["id"], newcomers["age"])
    new <- list()
    new[['date']] <- enddate
    new[['persons']] <- aux
    createJSON (new, paste(c(destdir, "/scm-demographics-birth.json"), collapse=''))
}

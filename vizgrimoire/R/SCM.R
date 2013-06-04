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

GetSCMEvolutionaryData <- function(period, startdate, enddate, i_db=NA, repository_name=NA, company_name=NA, country_name=NA){

    # 1- Retrieving information
    commits <- EvolCommits(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    authors <- EvolAuthors(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    committers <- EvolCommitters(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    files <- EvolFiles(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    lines <- EvolLines(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    branches <- EvolBranches(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    repositories <- EvolRepositories(period, startdate, enddate, i_db, repository_name, company_name, country_name)

    # 2- Merging information
    evol_data = merge(commits, committers, all = TRUE)
    evol_data = merge(evol_data, authors, all = TRUE)
    evol_data = merge(evol_data, files, all = TRUE)
    evol_data = merge(evol_data, lines, all = TRUE)
    evol_data = merge(evol_data, branches, all = TRUE)
    evol_data = merge(evol_data, repositories, all = TRUE)

    return (evol_data)
}

GetSCMStaticData <- function(period, startdate, enddate, i_db=NA, repository_name=NA, company_name=NA, country_name=NA){

    # 1- Retrieving information
    static_commits <- StaticNumCommits(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_committers <- StaticNumAuthors(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_authors <- StaticNumCommitters(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_files <- StaticNumFiles(period, conf$startdate, enddate, i_db, repository_name, company_name, country_name)
    static_branches <- StaticNumBranches(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_repositories <- StaticNumRepositories(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_actions <- StaticNumActions(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    static_lines <- StaticNumLines(period, conf$startdate, enddate, i_db, repository_name, company_name, country_name)
    avg_commits_period <- StaticAvgCommitsPeriod(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    avg_files_period <- StaticAvgFilesPeriod(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    avg_commits_author <- StaticAvgCommitsAuthor(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    avg_authors_period <- StaticAvgAuthorPeriod(period, startdate, conf$enddate, i_db, repository_name, company_name, country_name)
    avg_committer_period <- StaticAvgCommitterPeriod(period, startdate, enddate, i_db, repository_name, company_name, country_name)
    avg_files_author <- StaticAvgFilesAuthor(period, startdate, enddate, i_db, repository_name, company_name, country_name)

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
EvolCommits <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    fields ='count(s.id) AS commits'
    tables = paste("scmlog s", GetSQLReportFrom(identities_db, repository, company, country))
    filters = GetSQLReportWhere(repository, company, country, "author")
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


EvolAuthors <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    fields <- 'count(distinct(pup.upeople_id)) AS authors '
    tables <- "scmlog s "
    filters = GetSQLReportWhere(repository, company, country, "author")

    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id", sep="")
    }
    
    if (! is.na(repository)){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.author_id = pup.people_id ", sep="")
    }
    
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolCommitters <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    fields <- 'count(distinct(pup.upeople_id)) AS committers '
    tables <- "scmlog s "
    filters = GetSQLReportWhere(repository, company, country, "committer")
    
    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables <- paste(tables, " ,  ",identities_db,".people_upeople pup ", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id", sep="")
    }
    if (! is.na(repository)){
        #Adding people_upeople table
        tables <- paste(tables, ",  ",identities_db,".people_upeople pup", sep="")
        filters <- paste(filters, " and s.committer_id = pup.people_id ", sep="")
    }

    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


EvolFiles <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    #Evolution of files
    
    fields <- 'count(distinct(a.file_id)) as files  '
    tables <- "scmlog s, actions a "
    filters = "a.commit_id = s.id "
    
    #specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(repository, company, country, "author"))
    
    #executing the query
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


EvolLines <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    #Evolution of files

    # basic parts of the query
    fields <- "sum(cl.added) as added_lines, sum(cl.removed) as removed_lines"
    tables <- "scmlog s, commits_lines cl "
    filters <- "cl.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(repository, company, country, "author"))
    
    #executing the query
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    data$negative_removed_lines <- -data$removed_lines
    return (data)
}


EvolBranches <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    #Evolution of files

    # basic parts of the query
    fields <- "count(distinct(a.branch_id)) as branches "
    tables <- " scmlog s, actions a "
    filters <- " a.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- paste(filters, GetSQLReportWhere(repository, company, country, "author"))
    
    #executing the query
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolRepositories <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA){
    #Evolution of commits

    # basic parts of the query
    fields <- "count(distinct(s.repository_id)) AS repositories "
    tables <- "scmlog s "

    # specific parts of the query depending on the report needed
    tables <- paste(tables, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters <- GetSQLReportWhere(repository, company, country, "author")
    
    #executing the query
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
            startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

#############
#Static numbers
#############

StaticNumCommits <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {
    #TODO: first_date and last_date should be in another function
    select <- "SELECT count(s.id) as commits,
               DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
               DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date "
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                     s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    print (q)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticNumAuthors <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {
   
    select <- "select count(distinct(pup.upeople_id)) AS authors "
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                     s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id", sep="")
    }

    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id ", sep="")
    }
    

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticNumCommitters <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {
  
    select <- "select count(distinct(pup.upeople_id)) AS committers "
    from <- " FROM scmlog s "
    where <- paste(" where  s.date >=", startdate, " and
                     s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "committer"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.committer_id = pup.people_id", sep="")
    }

    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.committer_id = pup.people_id ", sep="")
    }


    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticNumFiles <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {
   
    select <- "SELECT count(distinct(file_id)) as files "
    from <- " FROM scmlog s, 
                   actions a "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           a.commit_id = s.id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}


StaticNumBranches <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {
   
    select <- "SELECT count(distinct(a.branch_id)) as branches "
    from <- " FROM scmlog s,
                   actions a "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           a.commit_id = s.id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}


StaticNumRepositories <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- "SELECT count(distinct(s.repository_id)) as repositories "
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticNumActions <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- "SELECT count(distinct(a.id)) as actions "
    from <- " FROM scmlog s,
                   actions a "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           a.commit_id = s.id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticNumLines <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- "select sum(cl.added) as added_lines,
               sum(cl.removed) as removed_lines "
    from <- " FROM scmlog s,
                   commits_lines cl "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           cl.commit_id = s.id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}

StaticAvgCommitsPeriod <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- paste("select count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period, sep="")
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}
	
StaticAvgFilesPeriod <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period, sep="")
    from <- " FROM scmlog s,
                   actions a "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           s.id = a.commit_id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

}
	
StaticAvgCommitsAuthor <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- "select count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author "
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id", sep="")
    }

    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id ", sep="")
    }



    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    
}

StaticAvgAuthorPeriod <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period, sep="")
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id", sep="")
    }

    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id ", sep="")
    }



    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    
}

StaticAvgCommitterPeriod <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period, sep="")
    from <- " FROM scmlog s "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where <- paste(where, GetSQLReportWhere(repository, company, country, "committer"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.committer_id = pup.people_id", sep="")
    }

    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.committer_id = pup.people_id ", sep="")
    }



    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    
}

	
StaticAvgFilesAuthor <- function(period, startdate, enddate, identities_db=NA, repository=NA, company=NA, country=NA) {

    select <- "select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author "
    from <- " FROM scmlog s,
                   actions a "
    where <- paste(" where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           s.id = a.commit_id ", sep="")
    rest <- ""

    # specific parts of the query depending on the report needed
    from <- paste(from, GetSQLReportFrom(identities_db, repository, company, country))
    where <- paste(where, GetSQLReportWhere(repository, company, country, "author"))

    if (is.na(repository) &&  is.na(company) && is.na(country)){
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        from <- paste(from, ",  people_upeople pup", sep="")
        where <- paste(where, " and s.committer_id = pup.people_id", sep="")
    }
    if (! is.na(repository)){
        #Adding people_upeople table
        from <- paste(from, ",  ",identities_db,".people_upeople pup", sep="")
        where <- paste(where, " and s.author_id = pup.people_id ", sep="")
    }

    #executing the query
    q <- paste(select, from, where, rest)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)    

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

evol_commits <- function(period, startdate, enddate){
      #Commits evolution

      print ("WARNING: evol_commits is a deprecated function, use instead EvolCommits")
      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                         count(distinct(s.id)) as commits
                  from   scmlog s 
                  where  s.date >=", startdate, " and
                         s.date < ", enddate,"
                         GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")
      
      query <- new ("Query", sql = q)
      data_commits <- run(query)
      return (data_commits)
}


evol_committers <- function(period, startdate, enddate){
      #Committers evolution

      print ("WARNING: evol_committers is a deprecated function, use instead EvolCommiters")
      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                         count(distinct(pup.upeople_id)) as committers
                  from   scmlog s,
                         people_upeople pup
                  where s.committer_id = pup.people_id and
                        s.date >=", startdate, " and
                        s.date < ", enddate, "
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

      query <- new ("Query", sql = q)
      data_committers <- run(query)
      return (data_committers)
}

evol_authors <- function(period, startdate, enddate){
	# Authors evolution

       print ("WARNING: evol_authors is a deprecated function, use instead EvolAuthors")
       q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(pup.upeople_id)) as authors
                   from   scmlog s,
                          people_upeople pup
                   where s.author_id = pup.people_id and
                         s.date >=", startdate, " and
                         s.date < ", enddate, "
                   GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")")

    query <- new ("Query", sql = q)
    data_authors <- run(query)
	return (data_authors)
}



evol_files <- function(period, startdate, enddate){
    
      #Files per ",period,"
      print ("WARNING: evol_files is a deprecated function, use instead EvolFiles")
      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(a.file_id)) as files
                  from   scmlog s, 
                         actions a
                  where  a.commit_id = s.id and
                         s.date >=", startdate, " and
                         s.date < ", enddate, "                         
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")
    
      query <- new ("Query", sql = q)
      data_files <- run(query)
      return (data_files)
}

evol_lines <- function(period, startdate, enddate) {

        # Lines added & removed per ",period,"
	print ("WARNING: evol_lines is a deprecated function, use instead EvolLines")
        q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           sum(cl.added) as added_lines,
                           sum(cl.removed) as removed_lines
                    from   commits_lines cl,
                           scmlog s
                    where  cl.commit_id = s.id
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="") 

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}


evol_branches <- function(period, startdate, enddate){
    
      #Branches per ",period,"
       print ("WARNING: evol_branches is a deprecated function, use instead EvolBranches")
       q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(a.branch_id)) as branches
                   from scmlog s, 
                   actions a
                   where  a.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                   group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

      query <- new ("Query", sql = q)
      data_branches <- run(query)
      return (data_branches)
}


evol_repositories <- function(period, startdate, enddate) {
    
      # Repositories per ",period,"
      print ("WARNING: evol_repositories is a deprecated function, use instead EvolRepositories")
      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id, 
                         count(distinct(s.repository_id)) as repositories
                  from scmlog s
                  where s.date >=", startdate, " and
                        s.date < ", enddate, "
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

      query <- new ("Query", sql = q)
      data_repositories <- run(query)
      return (data_repositories)
}

EvolCompanies <- function(period, startdate, enddate){	

    fields = "count(distinct(upc.company_id)) as companies"
    tables = " scmlog s, people_upeople pup, upeople_companies upc"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upc.upeople_id and
               s.date >= upc.init and 
               s.date < upc.end"
    q <- GetSQLPeriod(period,'s.date', fields, tables, filters, 
                           startdate, enddate)
    print(q)       
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

evol_info_data <- function(period, startdate, enddate) {
	# Get some general stats from the database
	## 
        print ("WARNING, deprecated function, use instead StaticXXX functions")
	q <- paste("SELECT count(s.id) as commits, 
                    count(distinct(pup.upeople_id)) as authors, 
                    DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
                    DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date 
                    FROM scmlog s,
                         people_upeople pup
                    where s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data0 <- run(query)
    
	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    from scmlog s,
                         people_upeople pup
                    where s.committer_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	
	q <- paste("SELECT count(distinct(a.branch_id)) as branches 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data2 <- run(query)	
	
	q <- paste("SELECT count(distinct(file_id)) as files 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data3 <- run(query)	
	
	q <- paste("SELECT count(distinct(s.repository_id)) as repositories 
                    from scmlog s
                    where s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data4 <- run(query)	
	
	q <- paste("SELECT count(distinct(a.id)) as actions 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)	
	
	q <- paste("select uri as url,type from repositories limit 1")
	query <- new("Query", sql = q)
	data6 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period," 
                    from scmlog s
                    where s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data7 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period," 
                    from scmlog s, 
                         actions a 
                    where a.commit_id=s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data8 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author 
                    from scmlog s, 
                    people_upeople pup 
                    where pup.people_id=s.author_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data9 <- run(query)	
	
	q <- paste("select count(distinct(s.author_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period," 
                    from scmlog s
                    where s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data10 <- run(query)	
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_committers_",period," 
                    from scmlog s,
                    people_upeople pup
                    where s.committer_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data11 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author
                    from scmlog s, 
                         actions a,
                    people_upeople pup
                    where a.commit_id=s.id and
                          s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data12 <- run(query)	
	
	agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
	agg_data = merge(agg_data, data3)
	agg_data = merge(agg_data, data4)
	agg_data = merge(agg_data, data5)
	agg_data = merge(agg_data, data6)
	agg_data = merge(agg_data, data7)
	agg_data = merge(agg_data, data8)
	agg_data = merge(agg_data, data9)
	agg_data = merge(agg_data, data10)
	agg_data = merge(agg_data, data11)
	agg_data = merge(agg_data, data12)	
	
	return (agg_data)
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

company_commits <- function(company_name, period, startdate, enddate){		
	print (company_name)

       print ("WARNING: company_commits is a deprecated function, use instead EvolCommits")
       q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(s.id)) as commits
                   from scmlog s,
                        people_upeople pup,
                        upeople_companies upc,
                        companies c
                    where  s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and
                           s.date < upc.end and
                           upc.company_id = c.id and
                           c.name =", company_name, " and
                           s.date >=", startdate, " and
                           s.date < ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

company_files <- function(company_name, period, startdate, enddate) {
	
        print ("WARNING: company_files is a deprecated function, use instead EvolFiles")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                            count(distinct(a.file_id)) as files
                    from scmlog s,
                         actions a,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where a.commit_id = s.id and
                          s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          c.name =", company_name, " and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_authors <- function(company_name, period, startdate, enddate) {		
	
        print ("WARNING: company_authors is a deprecated function, use instead EvolAuthors")
        q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                            count(distinct(s.author_id)) as authors
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where  s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date>=upc.init and
                           s.date<upc.end and
                           upc.company_id = c.id and
                           c.name =", company_name, " and
                           s.date >=", startdate, " and
                           s.date < ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_committers <- function(company_name, period, startdate, enddate) {		
	
        print ("WARNING: company_committers is a deprecated function, use instead EvolCommitters")
        q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           count(distinct(s.committer_id)) as committers
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where  s.committer_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and
                           s.date < upc.end and
                           upc.company_id = c.id and
                           c.name =", company_name, " and
                           s.date >=", startdate, " and
                           s.date < ", enddate, "
                     group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_lines <- function(company_name, period, startdate, enddate) {
	
	print ("WARNING: company_lines is a deprecated function, use instead EvolLines")
        q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           sum(cl.added) as added_lines,
                           sum(cl.removed) as removed_lines
                    from   commits_lines cl,
                           scmlog s,
                           people_upeople pup,
                           upeople_companies upc,
                           companies c
                    where  cl.commit_id = s.id and
                           s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and
                           s.date < upc.end and
                           upc.company_id = c.id and
                           c.name =", company_name, " and
                           s.date >=", startdate, " and
                           s.date < ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="") 

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

evol_info_data_company <- function(company_name, period, startdate, enddate) {
	
	# Get some general stats from the database
	##
        print ("WARNING, deprecated function, use instead StaticXXX functions")
	q <- paste("SELECT count(distinct(s.id)) as commits, 
                           count(distinct(pup.upeople_id)) as authors,
                           DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                           DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                    FROM   scmlog s,
                           people_upeople pup,
                           upeople_companies upc,
                           companies c
                    where  s.author_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and 
                           s.date < upc.end and
                           upc.company_id = c.id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data0 <- run(query)
    
    q <- paste("SELECT count(distinct(pup.upeople_id)) as committers,
                           DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                           DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                    FROM   scmlog s,
                           people_upeople pup,
                           upeople_companies upc,
                           companies c
                    where  s.committer_id = pup.people_id and
                           pup.upeople_id = upc.upeople_id and
                           s.date >= upc.init and
                           s.date < upc.end and
                           upc.company_id = c.id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           c.name =", company_name, ";", sep="")
        query <- new("Query", sql = q)
        data1 <- run(query)

        date0s <- as.Date(data0$first_date)
        date0e <- as.Date(data0$last_date)
        date1s <- as.Date(data1$first_date)
        date1e <- as.Date(data1$last_date)
        
        if (!is.na(date0s) && !is.na(date1s) && (date0s > date1s)) {
            data0$first_date = data1$first_date
        }
        if (!is.na(date0e) && !is.na(date1e) && (date0e < date1e)) {
            data0$last_date = data1$last_date
        }
        data1$first_date = data0$first_date
        data1$last_date = data0$last_date
                
        agg_data = merge(data0, data1)            
        
	q <- paste("SELECT count(distinct(file_id)) as files
                    from actions a,
                         scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where a.commit_id = s.id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data3 <- run(query)
	
	q <- paste("SELECT count(*) as actions 
                    from actions a, 
                         scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.id = a.commit_id and
                         s.date >= upc.init and 
                         s.date < upc.end and
                         s.author_id = pup.people_id and
                         pup.upeople_id = upc.upeople_id and
                         upc.company_id = c.id and
                         s.date >=", startdate, " and
                         s.date < ", enddate, " and
                         c.name =", company_name,";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)
    
	q <- paste("select count(s.id)/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period,"
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data7 <- run(query)	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period,"
                    from scmlog s, 
                         actions a,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where a.commit_id=s.id and
                          s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data8 <- run(query)	

	q <- paste("select count(distinct(s.id))/count(distinct(s.author_id)) as avg_commits_author
                    from scmlog s, 
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data9 <- run(query)	

	q <- paste("select count(distinct(s.author_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period,"
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and 
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data10 <- run(query)	

	q <- paste("select count(distinct(a.file_id))/count(distinct(s.author_id)) as avg_files_author
                    from scmlog s, 
                         actions a,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where a.commit_id=s.id and
                          s.author_id is not null and
                          s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date < upc.end and
                          upc.company_id = c.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and 
                          c.name =", company_name)
	query <- new("Query", sql = q)
	data11 <- run(query)
	    
    agg_data = merge(data0, data1)
	agg_data = merge(agg_data, data3)
	agg_data = merge(agg_data, data5)
	agg_data = merge(agg_data, data7)
	agg_data = merge(agg_data, data8)
	agg_data = merge(agg_data, data9)
	agg_data = merge(agg_data, data10)
	agg_data = merge(agg_data, data11)
	return (agg_data)
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

repo_commits <- function(repo_name, period, startdate, enddate){
	
        print ("WARNING: repo_commits is a deprecated function, use instead EvolCommits")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                            COUNT(distinct(s.id)) as commits
                    FROM scmlog s, repositories r
                    WHERE r.name =", repo_name, " AND 
                          r.id = s.repository_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}

repo_files <- function(repo_name, period, startdate, enddate) {
	
        print ("WARNING: repo_files is a deprecated function, use instead EvolFiles")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           COUNT(distinct(a.file_id)) as files
                    FROM scmlog s, actions a, repositories r
                    WHERE r.name =", repo_name, " AND 
                          r.id = s.repository_id and
                          a.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}


repo_committers <- function(repo_name, period, startdate, enddate) {
	
        print ("WARNING: repo_committers is a deprecated function, use instead EvolCommitters")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           COUNT(distinct(pup.upeople_id)) as committers
                    FROM scmlog s,
                         people_upeople pup,
                         repositories r
                    WHERE r.name =", repo_name, " AND
                          r.id = s.repository_id and
                          s.committer_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}


repo_authors <- function(repo_name, period, startdate, enddate) {
	
        print ("WARNING: repo_authors is a deprecated function, use instead EvolAuthors")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           COUNT(distinct(pup.upeople_id)) as authors
                    FROM scmlog s,
                         people_upeople pup,
                         repositories r
                    WHERE r.name =", repo_name, " AND
                          r.id = s.repository_id and
                          s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                    GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}

repo_lines <- function(repo_name, period, startdate, enddate) {
	
        print ("WARNING: repo_lines is a deprecated function, use instead EvolLines")
        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           SUM(cl.added) as added_lines,
                           SUM(cl.removed) as removed_lines
                    FROM scmlog s, commits_lines cl, repositories r
                    WHERE r.name =", repo_name, " AND
                          r.id = s.repository_id and
                          cl.commit_id = s.id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, "
                   GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

	query <- new("Query", sql = q)
	data <- run(query)
	return (data)				
}

evol_info_data_repo <- function(repo_name, period, startdate, enddate) {
	
	# Get some general stats from the database
	##
        print ("WARNING, deprecated function, use instead StaticXXX functions")
	q <- paste("SELECT count(s.id) as commits, 
                           count(distinct(pup.upeople_id)) as authors,
                           DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                           DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data0 <- run(query)

	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.committer_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	q <- paste("SELECT count(distinct(file_id)) as files, 
                           count(*) as actions
                    FROM actions a, 
                         scmlog s, 
                         repositories r
                    WHERE a.commit_id = s.id AND
                          r.id = s.repository_id AND
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data2 <- run(query)
	
	q <- paste("select count(s.id)/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period,"
                    FROM scmlog s, 
                         repositories r
                    WHERE r.id = s.repository_id AND
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data3 <- run(query)
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period,"
                    FROM scmlog s, 
                         actions a, 
                         repositories r
                    WHERE a.commit_id=s.id AND
                          r.id = s.repository_id AND
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data4 <- run(query)
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) AS avg_commits_author
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) AS avg_authors_",period,"
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.author_id = pup.people_id and
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and 
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data6 <- run(query)
	
	q <- paste("select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) AS avg_files_author
                    FROM scmlog s, 
                         actions a, 
                         repositories r,
                         people_upeople pup
                    WHERE a.commit_id=s.id AND
                          s.author_id = pup.people_id and
                          r.id = s.repository_id AND
                          s.date >=", startdate, " and
                          s.date < ", enddate, " and
                          r.name =", repo_name, ";", sep="")
        query <- new("Query", sql = q)
        data7 <- run(query)
	
        agg_data = merge(data0, data1)
        agg_data = merge(agg_data, data2)
        agg_data = merge(agg_data, data3)
        agg_data = merge(agg_data, data4)
        agg_data = merge(agg_data, data5)
        agg_data = merge(agg_data, data6)
        agg_data = merge(agg_data, data7)
        return (agg_data)
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

scm_countries_evol <- function(identities_db, country, period, startdate, enddate) {
    
    rol = "author" #committer
    print ("WARNING: scm_countries_evol is a deprecated function, use instead EvolCommits")
    q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                count(s.id) AS commits,
                COUNT(DISTINCT(s.",rol,"_id)) as ", rol,"s
                FROM scmlog s, 
                     people_upeople pup,
                     ",identities_db,".countries c,
                     ",identities_db,".upeople_countries upc
                WHERE pup.people_id = s.",rol,"_id AND
                      pup.upeople_id  = upc.upeople_id and
                      upc.country_id = c.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, " and
                      c.name = '", country, "'
                GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

scm_countries_static <- function(identities_db, country, startdate, enddate) {
    rol = "author" #committer
    
    q <- paste("SELECT count(s.id) AS commits,
                       COUNT(DISTINCT(s.",rol,"_id)) as ", rol,"s,
                       DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                       DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                FROM scmlog s, 
                     people_upeople pup,
                     ",identities_db,".countries c,
                     ",identities_db,".upeople_countries upc
                WHERE pup.people_id = s.",rol,"_id AND
                      pup.upeople_id  = upc.upeople_id and
                      upc.country_id = c.id and
                      s.date >=", startdate, " and
                      s.date < ", enddate, " and
                      c.name = '", country, "'", sep="")
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

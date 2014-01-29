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

import re, sys

from GrimoireSQL import GetSQLGlobal, GetSQLPeriod, GetSQLReportFrom
from GrimoireSQL import GetSQLReportWhere, ExecuteQuery, BuildQuery
from GrimoireUtils import GetPercentageDiff, GetDates, completePeriodIds
import GrimoireUtils

##########
# Meta-functions to automatically call metrics functions and merge them
##########

def GetSCMEvolutionaryData (period, startdate, enddate, i_db, type_analysis):
    # Meta function that includes basic evolutionary metrics from the source code
    # management system. Those are merged and returned.

    # 1- Retrieving information
    commits = EvolCommits(period, startdate, enddate, i_db, type_analysis)
    authors = EvolAuthors(period, startdate, enddate, i_db, type_analysis)
    committers = EvolCommitters(period, startdate, enddate, i_db, type_analysis)
    files = EvolFiles(period, startdate, enddate, i_db, type_analysis)
    lines = EvolLines(period, startdate, enddate, i_db, type_analysis)
    branches = EvolBranches(period, startdate, enddate, i_db, type_analysis)
    repositories = EvolRepositories(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    evol = dict(commits.items() + repositories.items() + committers.items())
    evol = dict(evol.items() + authors.items() + files.items())
    evol = dict(evol.items() + lines.items() + branches.items())

    return (evol)


def GetSCMStaticData (period, startdate, enddate, i_db, type_analysis):
    # Meta function that includes basic aggregated metrics from the source code
    # management system. Those are merged and returned.

    # 1- Retrieving information
    commits = StaticNumCommits(period, startdate, enddate, i_db, type_analysis)
    authors = StaticNumAuthors(period, startdate, enddate, i_db, type_analysis)
    committers = StaticNumCommitters(period, startdate, enddate, i_db, type_analysis)
    files = StaticNumFiles(period, startdate, enddate, i_db, type_analysis)
    branches = StaticNumBranches(period, startdate, enddate, i_db, type_analysis)
    repositories = StaticNumRepositories(period, startdate, enddate, i_db, type_analysis)
    actions = StaticNumActions(period, startdate, enddate, i_db, type_analysis)
    lines = StaticNumLines(period, startdate, enddate, i_db, type_analysis)
    avg_commits_period = StaticAvgCommitsPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_files_period = StaticAvgFilesPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_commits_author = StaticAvgCommitsAuthor(period, startdate, enddate, i_db, type_analysis)
    avg_authors_period = StaticAvgAuthorPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_committer_period = StaticAvgCommitterPeriod(period, startdate, enddate, i_db, type_analysis)
    avg_files_author = StaticAvgFilesAuthor(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    agg = dict(commits.items() + repositories.items() + committers.items())
    agg = dict(agg.items() + authors.items() + files.items() + actions.items())
    agg = dict(agg.items() + lines.items() + branches.items())
    agg = dict(agg.items() + avg_commits_period.items() + avg_files_period.items())
    agg = dict(agg.items() + avg_commits_author.items() + avg_files_author.items())

    return (agg)
##########
# Specific FROM and WHERE clauses per type of report
##########
def GetSQLRepositoriesFrom ():
    #tables necessaries for repositories
    return (" , repositories r")


def GetSQLRepositoriesWhere (repository):
    #fields necessaries to match info among tables
    return (" and r.name ="+ repository + \
            " and r.id = s.repository_id")


def GetSQLCompaniesFrom (identities_db):
    #tables necessaries for companies
    return (" , "+identities_db+".people_upeople pup,"+\
                  identities_db+".upeople_companies upc,"+\
                  identities_db+".companies c")


def GetSQLCompaniesWhere (company, role):
    #fields necessaries to match info among tables
    return ("and s."+role+"_id = pup.people_id "+\
            "  and pup.upeople_id = upc.upeople_id "+\
            "  and s.date >= upc.init "+\
            "  and s.date < upc.end "+\
            "  and upc.company_id = c.id "+\
            "  and c.name =" + company)


def GetSQLCountriesFrom (identities_db):
    #tables necessaries for companies
    return (" , ",identities_db,".people_upeople pup,
                  ",identities_db,".upeople_countries upc,
                  ",identities_db,".countries c")


def GetSQLCountriesWhere (country, role):
    #fields necessaries to match info among tables
    return ("and s.",role,"_id = pup.people_id
                  and pup.upeople_id = upc.upeople_id
                  and upc.country_id = c.id
                  and c.name =", country)


def GetSQLDomainsFrom (identities_db) :
    #tables necessaries for domains
    return (" , ",identities_db,".people_upeople pup,
                            ",identities_db,".upeople_domains upd,
                            ",identities_db,".domains d")


def GetSQLDomainsWhere (domain, role) :
    #fields necessaries to match info among tables
    return ("and s.",role,"_id = pup.people_id
                            and pup.upeople_id = upd.upeople_id
                            and upd.domain_id = d.id
                            and d.name =", domain)


##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

def GetSQLReportFrom (identities_db, type_analysis):
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]

    from = ""

    if (! is.na(analysis)):
        from = ifelse (analysis == 'repository', from, GetSQLRepositoriesFrom()),
                ifelse (analysis == 'company', from, GetSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', from, GetSQLCountriesFrom(identities_db)),
                ifelse (analysis == 'domain', from, GetSQLDomainsFrom(identities_db)),
                NA))))
    
    return (from)



def GetSQLReportWhere (type_analysis, role):
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)):
        where = ifelse (analysis == 'repository', where, GetSQLRepositoriesWhere(value)),
                 ifelse (analysis == 'company', where, GetSQLCompaniesWhere(value, role)),
                 ifelse (analysis == 'country', where, GetSQLCountriesWhere(value, role)),
                 ifelse (analysis == 'domain', where, GetSQLDomainsWhere(value, role)),
                 NA))))
    
    return (where)


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


def GetCommits (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count commits.
    # That query is built and results returned.

    fields = " count(distinct(s.id)) as commits "
    tables = " scmlog s, actions a ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author"), " and s.id=a.commit_id ") 
    
    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolCommits (period, startdate, enddate, identities_db, type_analysis):
    # Returns the evolution of commits through the time

    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, TRUE))


#StaticNumCommits (period, startdate, enddate, identities_db, type_analysis):
#    return(GetCommits(period, startdate, enddate, identities_db, type_analysis, FALSE))
#


def GetAuthors (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count authors
    # That query is later built and executed

    fields = " count(distinct(pup.upeople_id)) AS authors "
    tables = " scmlog s " 
    filters = GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) :
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id"
    

    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolAuthors (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of authors through the time
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumAuthors (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregated number of authors in the specified timeperiod (enddate - startdate)
    return (GetAuthors(period, startdate, enddate, identities_db, type_analysis, FALSE))


def GetDiffAuthorsDays (period, init_date, identities_db, days):
    # This function provides the percentage in activity between two periods:

    chardates = GetDates(init_date, days)
    lastauthors = StaticNumAuthors(period, chardates[2], chardates[1], identities_db)
    lastauthors = as.numeric(lastauthors[1])
    prevauthors = StaticNumAuthors(period, chardates[3], chardates[2], identities_db)
    prevauthors = as.numeric(prevauthors[1])
    diffauthorsdays = data.frame(diff_netauthors = numeric(1), percentage_authors = numeric(1))
    diffauthorsdays$diff_netauthors = lastauthors - prevauthors
    diffauthorsdays$percentage_authors = GetPercentageDiff(prevauthors, lastauthors)

    colnames(diffauthorsdays) = c("diff_netauthors","_",days, "percentage_authors","_",days)

    return (diffauthorsdays)



def GetCommitters (period, startdate, enddate, identities_db, type_analysis, evolutionary) :
    # This function contains basic parts of the query to count committers
    # That query is later built and executed

    fields = 'count(distinct(pup.upeople_id)) AS committers '
    tables = "scmlog s "
    filters = GetSQLReportWhere(type_analysis, "committer")

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1]) ):
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, " ,  ",identities_db,".people_upeople pup "
        filters = filters, " and s.committer_id = pup.people_id"
    
    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.committer_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolCommitters (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of the number of committers through the time
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumCommitters (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregate number of committers in the specified timeperiod (enddate - startdate)
    return(GetCommitters(period, startdate, enddate, identities_db, type_analysis, FALSE))



def GetFiles (period, startdate, enddate, identities_db, type_analysis, evolutionary) :
    # This function contains basic parts of the query to count files
    # That query is later built and executed

    fields = " count(distinct(a.file_id)) as files "
    tables = " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters = filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolFiles (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of the number of files through the time
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumFiles (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregate number of unique files in the specified timeperiod (enddate - startdate)
    return (GetFiles(period, startdate, enddate, identities_db, type_analysis, FALSE))


def GetDiffFilesDays (period, init_date, identities_db, days):
    # This function provides the percentage in activity between two periods:

    chardates = GetDates(init_date, days)
    lastfiles = StaticNumFiles(period, chardates[2], chardates[1], identities_db)
    lastfiles = as.numeric(lastfiles[1])
    prevfiles = StaticNumFiles(period, chardates[3], chardates[2], identities_db)
    prevfiles = as.numeric(prevfiles[1])
    diff_files_days = data.frame(diff_netfiles = numeric(1), percentage_files = numeric(1))
    diff_files_days$diff_netfiles = lastfiles - prevfiles
    diff_files_days$percentage_files = GetPercentageDiff(prevfiles, lastfiles)

    colnames(diff_files_days) = c("diff_netfiles","_",days, "percentage_files","_",days)

    return (diff_files_days)



def GetLines (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count lines
    # That query is later built and executed

    # basic parts of the query
    fields = "sum(cl.added) as added_lines, sum(cl.removed) as removed_lines"
    tables = "scmlog s, commits_lines cl "
    filters = "cl.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters = filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    data = ExecuteQuery(q)
    if (length(data)>0) :data$negative_removed_lines = -data$removed_lines
    return (data)


def EvolLines (period, startdate, enddate, identities_db, type_analysis) :
    # returns the evolution of the number of lines through the time
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumLines (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregate number of lines in the specified timeperiod (enddate - startdate)
    return (GetLines(period, startdate, enddate, identities_db, type_analysis, FALSE))


def GetDiffLinesDays (period, init_date, identities_db, days):
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

    colnames(diff_lines_days) = c("diff_netadded_lines","_",days,
                                   "percentage_added_lines","_",days,
                                   "diff_netremoved_lines","_",days,
                                   "percentage_removed_lines","_",days)

    return (diff_lines_days)

def GetBranches (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count branches
    # That query is later built and executed
    
    # basic parts of the query
    fields = "count(distinct(a.branch_id)) as branches "
    tables = " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    # specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters = filters, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolBranches (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of the number of branches through the time
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumBranches (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregate number of branches in the specified timeperiod (enddate - startdate)
    return (GetBranches(period, startdate, enddate, identities_db, type_analysis, FALSE))


def GetRepositories (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count repositories
    # That query is later built and executed

    # basic parts of the query
    fields = "count(distinct(s.repository_id)) AS repositories "
    tables = "scmlog s "

    # specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    filters = GetSQLReportWhere(type_analysis, "author")
    
    #executing the query
    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolRepositories (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of the number of repositories through the time
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumRepositories (period, startdate, enddate, identities_db, type_analysis):
    # returns the aggregate number of repositories in the specified timeperiod (enddate - startdate)
    return (GetRepositories(period, startdate, enddate, identities_db, type_analysis, FALSE))


def StaticNumCommits (period, startdate, enddate, identities_db, type_analysis) :
    # returns the aggregate number of commits in the specified timeperiod (enddate - startdate)
    # TODO: this function is deprecated, but the new one is not ready yet. This should directly call
    #       GetCommits as similarly done by EvolCommits function.

    #TODO: first_date and last_date should be in another function
    select = "SELECT count(distinct(s.id)) as commits,
               DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
               DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date "
    from = " FROM scmlog s, actions a " 
    where = " where s.date >=", startdate, " and
                     s.date < ", enddate, " and
                     s.id = a.commit_id "
    rest = ""

    # specific parts of the query depending on the report needed
    from = from, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where = where, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q = select, from, where, rest)

    return(ExecuteQuery(q))


def GetDiffCommitsDays (period, init_date, days):
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

    colnames(diffcommitsdays) = c("diff_netcommits","_",days, "percentage_commits","_",days)

    return (diffcommitsdays)



def GetActions (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # This function contains basic parts of the query to count actions.
    # An action is any type of change done in a file (addition, copy, removal, etc)
    # That query is later built and executed

    fields = " count(distinct(a.id)) as actions "
    tables = " scmlog s, actions a "
    filters = " a.commit_id = s.id "

    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    filters = filters, GetSQLReportWhere(type_analysis, "author"))

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


def EvolActions (period, startdate, enddate, identities_db, type_analysis):
    # returns the evolution of the number of actions through the time
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticNumActions (period, startdate, enddate, identities_db, type_analysis) :
    # returns the aggregate number of actions in the specified timeperiod (enddate - startdate)
    return(GetActions(period, startdate, enddate, identities_db, type_analysis, FALSE))


def StaticNumLines (period, startdate, enddate, identities_db, type_analysis) :
    # returns the aggregate number of repositories in the specified timeperiod (enddate - startdate)
    # TODO: this function is deprecated, this should call GetLines

    select = "select sum(cl.added) as added_lines,
               sum(cl.removed) as removed_lines "
    from = " FROM scmlog s,
                   commits_lines cl "
    where = " where s.date >=", startdate, " and
                           s.date < ", enddate, " and
                           cl.commit_id = s.id "
    rest = ""

    # specific parts of the query depending on the report needed
    from = from, GetSQLReportFrom(identities_db, type_analysis))
    #TODO: left "author" as generic option coming from parameters (this should be specified by command line)
    where = where, GetSQLReportWhere(type_analysis, "author"))

    #executing the query
    q = select, from, where, rest)
    return(ExecuteQuery(q))


def GetAvgCommitsPeriod (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of commits per period of time (day, week, month, etc...) 
    # in the specified timeperiod (enddate - startdate)

    fields = " count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    filters = filters, GetSQLReportWhere(type_analysis, "author")

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))


#EvolAvgCommitsPeriod (period, startdate, enddate, identities_db, type_analysis) :
#WARNING: This function should provide same information as EvolCommits, do not use this.
#    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#

def StaticAvgCommitsPeriod (period, startdate, enddate, identities_db, type_analysis) :
    # returns the average number of commits per period (weekly, monthly, etc) in the specified timeperiod (enddate - startdate)
    return (GetAvgCommitsPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))



def GetAvgFilesPeriod (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of files per period (Weekly, monthly, etc) in the specified
    # time period (enddate - startdate) 
    fields = " count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    tables = tables, GetSQLReportFrom(identities_db, type_analysis))
    filters = filters, GetSQLReportWhere(type_analysis, "author")

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


#EvolAvgFilesPeriod (period, startdate, enddate, identities_db, type_analysis):
#WARNING: this function should return same info as EvolFiles, do not use this
#    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#

def StaticAvgFilesPeriod (period, startdate, enddate, identities_db, type_analysis):
    # returns the average number of files per period (Weekly, monthly, etc) in the specified
    # time period (enddate - startdate)
    return (GetAvgFilesPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))



def GetAvgCommitsAuthor (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of commits per author in the specified
    # time period (enddate - startdate)

    fields = " count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author "
    tables = " scmlog s, actions a " 
    filters = " s.id = a.commit_id " 

    filters = filters, GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) :
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id"
    

    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))


def EvolAvgCommitsAuthor (period, startdate, enddate, identities_db, type_analysis):
    # returns the average number of commits per author in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticAvgCommitsAuthor (period, startdate, enddate, identities_db, type_analysis):
    # returns the average and total number of commits per author in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitsAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))



def GetAvgAuthorPeriod (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of authors per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

    fields = " count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period 
    tables = " scmlog s "
    filters = ""

    filters = GetSQLReportWhere(type_analysis, "author")

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) :
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id"
    

    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


#EvolAvgAuthorPeriod (period, startdate, enddate, identities_db, type_analysis):
#WARNING: this function should return same information as EvolAuthors, do not use this
#    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#

def StaticAvgAuthorPeriod (period, startdate, enddate, identities_db, type_analysis):
    # returns the average number of authors per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

    return (GetAvgAuthorPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))

def GetAvgCommitterPeriod (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of committers per period (weekly, monthly) in the specified
    # time period (enddate - startdate)

    fields = " count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period
    tables = " scmlog s "
    filters = ""

    filters = GetSQLReportWhere(type_analysis, "committer")

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) :
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.committer_id = pup.people_id"
    

    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.committer_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)

    return(ExecuteQuery(q))


#EvolAvgCommitterPeriod (period, startdate, enddate, identities_db, type_analysis):
#WARNING: this function should return same info as EvolCommitters, do not use this
#    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, TRUE))
#

def StaticAvgCommitterPeriod (period, startdate, enddate, identities_db, type_analysis):
    # returns the average number of committers per period (weekly, monthly) in the specified
    # time period (enddate - startdate)
    return (GetAvgCommitterPeriod(period, startdate, enddate, identities_db, type_analysis, FALSE))



def GetAvgFilesAuthor (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # returns the average number of files per author (weekly, monthly) in the specified
    # time period (enddate - startdate)    

    fields = " count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author "
    tables = " scmlog s, actions a "
    filters = " s.id = a.commit_id "

    filters = filters, GetSQLReportWhere(type_analysis, "author"))

    #specific parts of the query depending on the report needed
    tables = tables, GetSQLReportFrom(identities_db, type_analysis))

    if (is.na(type_analysis[1])) :
        #Specific case for the basic option where people_upeople table is needed
        #and not taken into account in the initial part of the query
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id"
    

    if (type_analysis[1] == "repository"):
        #Adding people_upeople table
        tables = tables, ",  ",identities_db,".people_upeople pup"
        filters = filters, " and s.author_id = pup.people_id "
    

    q = BuildQuery(period, startdate, enddate, " s.date ", fields, tables, filters, evolutionary)


    return(ExecuteQuery(q))


def EvolAvgFilesAuthor (period, startdate, enddate, identities_db, type_analysis) :
    # returns the average number of files per author and its evolution (weekly, monthly) in the specified
    # time period (enddate - startdate)  
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, TRUE))


def StaticAvgFilesAuthor (period, startdate, enddate, identities_db, type_analysis) :
    # returns the average number of files per author (weekly, monthly) in the specified
    # time period (enddate - startdate)  
    return(GetAvgFilesAuthor(period, startdate, enddate, identities_db, type_analysis, FALSE))

def StaticURL () :
    # Returns the SCM URL     

    q = "select uri as url,type from repositories limit 1")
	query = new("Query", sql = q)
	data = run(query)
	return (data)    


#
# People
#

def GetTablesOwnUniqueIdsSCM () :
    return ('scmlog s, people_upeople pup')


def GetFiltersOwnUniqueIdsSCM () :
    return ('pup.people_id = s.author_id') 


def GetPeopleListSCM (startdate, enddate) :
    fields = "DISTINCT(pup.upeople_id) as pid, COUNT(s.id) as total"
    tables = GetTablesOwnUniqueIdsSCM()
    filters = GetFiltersOwnUniqueIdsSCM()
    filters = filters,"GROUP BY pid ORDER BY total desc")
    q = GetSQLGlobal('s.date',fields,tables, filters, startdate, enddate)
	query = new("Query", sql = q)
	data = run(query)
	return (data)        

def GetPeopleQuerySCM (developer_id, period, startdate, enddate, evol) :
    fields ='COUNT(s.id) AS commits'
    tables = GetTablesOwnUniqueIdsSCM()
    filters = GetFiltersOwnUniqueIdsSCM()
    filters = filters,"AND pup.upeople_id=",developer_id)
    if (evol) :
        q = GetSQLPeriod(period,'s.date', fields, tables, filters, 
                startdate, enddate)
     else :
        fields = fields,
                ",DATE_FORMAT (min(s.date),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(s.date),'%Y-%m-%d') as last_date")        
        q = GetSQLGlobal('s.date', fields, tables, filters, 
                startdate, enddate)

    return (q)


def GetEvolPeopleSCM (developer_id, period, startdate, enddate) :
    q = GetPeopleQuerySCM (developer_id, period, startdate, enddate, TRUE)
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def GetStaticPeopleSCM (developer_id, startdate, enddate) :
    q = GetPeopleQuerySCM (developer_id, NA, startdate, enddate, FALSE)
    query = new("Query", sql = q)
    data = run(query)
    return (data)        


# 
# Legacy and non legacy code - Cleanup
#

def EvolCompanies (period, startdate, enddate):	
    # Returns the evolution in the provided period of the number of total companies

    fields = "count(distinct(upc.company_id)) as companies"
    tables = " scmlog s, people_upeople pup, upeople_companies upc"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upc.upeople_id and
               s.date >= upc.init and 
               s.date < upc.end"
    q = GetSQLPeriod(period,'s.date', fields, tables, filters, 
                           startdate, enddate)
    query = new("Query", sql = q)
	companies= run(query)
	return(companies)


def EvolCountries (period, startdate, enddate):	
    # Returns the evolution in the provided period of the number of total countries

    fields = "count(distinct(upc.country_id)) as countries"
    tables = "scmlog s, people_upeople pup, upeople_countries upc"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upc.upeople_id"
    q = GetSQLPeriod(period,'s.date', fields, tables, filters, 
               startdate, enddate)      
    query = new("Query", sql = q)
	countries= run(query)
	return(countries)


def EvolDomains (period, startdate, enddate):
    # Returns the evolution in the provided period of the number of total domains

    fields = "COUNT(DISTINCT(upd.domain_id)) AS domains"
    tables = "scmlog s, people_upeople pup, upeople_domains upd"
    filters = "s.author_id = pup.people_id and
               pup.upeople_id = upd.upeople_id"
    q = GetSQLPeriod(period,'s.date', fields, tables, filters,
            startdate, enddate)
    query = new("Query", sql = q)
    domains= run(query)
    return(domains)


def last_activity (days) :
    # Given a number of days, this function calculates the number of
    # commits, authors, files, added and removed lines that took place
    # in a project. 

    #commits
    q = "select count(*) as commits_",days,"
                from scmlog 
                where date >= (
                      select (max(date) - INTERVAL ",days," day) 
                      from scmlog)";
    query = new("Query", sql = q)
    data1 = run(query)

    #authors
    q = "select count(distinct(pup.upeople_id)) as authors_",days,"
                from scmlog s, 
                     people_upeople pup 
                where pup.people_id = s.author_id and 
                      s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)";
    query = new("Query", sql = q)
    data2 = run(query)


    #files
    q = "select count(distinct(a.file_id)) as files_",days,"
                from scmlog s, 
                     actions a 
                where a.commit_id = s.id and 
                      s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)";
    query = new("Query", sql = q)
    data3 = run(query)

    #added_removed lines
    q = " select sum(cl.added) as added_lines_",days,",
                        sum(cl.removed) as removed_lines_",days,"
                 from scmlog s, 
                      commits_lines cl 
                 where cl.commit_id = s.id and 
                       s.date >= (select (max(date) - INTERVAL ",days," day) from scmlog)";
    query = new("Query", sql = q)
    data4 = run(query)

    agg_data = merge(data1, data2)
    agg_data = merge(agg_data, data3)
    agg_data = merge(agg_data, data4)

    return (agg_data)


def top_people (days, startdate, enddate, role, filters="") :
    # This function returns the 10 top people participating in the source code.
    # Dataset can be filtered by the affiliations, where specific companies
    # can be ignored.
    # In addition, the number of days allows to limit the study to the last
    # X days specified in that parameter

    affiliations = ""
    for (aff in filters):
        affiliations = affiliations, " c.name<>'",aff,"' and ",sep="")
    
 
    date_limit = ""
    if (days != 0 ) :
        query = new("Query",
                sql = "SELECT @maxdate:=max(date) from scmlog limit 1")
        data = run(query)
        date_limit = " AND DATEDIFF(@maxdate, date)<",days)
    
    
    q = "SELECT u.id as id, u.identifier as ", role, "s,
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
               LIMIT 10;"
    query = new("Query", sql = q)
    data = run(query)
    return (data)	


def top_files_modified () :
      # Top 10 modified files

      #FIXME: to be updated to use stardate and enddate values
      q = "select file_name, count(commit_id) as modifications 
                  from action_files a join files f on a.file_id = f.id 
                  where action_type='M' 
                  group by f.id 
                  order by modifications desc limit 10; ")	
      query = new("Query", sql = q)
      data = run(query)
      return (data)	


## TODO: Follow top_committers implementation
def top_authors (startdate, enddate) :
    # Top 10 authors without filters

    q = "SELECT u.id as id, u.identifier as authors,
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
	query = new("Query", sql = q)
	data = run(query)
	return (data)



def top_authors_wo_affiliations (list_affs, startdate, enddate) :
    # top ten authors with affiliation removal
    #list_affs
    affiliations = ""
    for (aff in list_affs):
        affiliations = affiliations, " c.name<>'",aff,"' and ",sep="")

    q = "SELECT u.id as id, u.identifier as authors,
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
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def top_authors_year (year) :
   # Given a year, this functions provides the top 10 authors 
   # of such year
    q = "SELECT u.id as id, u.identifier as authors,
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
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def people () :
    # List of people participating in the source code development
 
    q = paste ("select id,identifier from upeople")
    query = new("Query", sql = q)
    data = run(query)
    return (data);

def companies_name_wo_affs (affs_list, startdate, enddate) :
    #List of companies without certain affiliations
    affiliations = ""
    for (aff in affs_list):
       affiliations = affiliations, " c.name<>'",aff,"' and ",sep="")

    q = paste ("select c.name
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
                 order by count(distinct(s.id)) desc;"
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def companies_name (startdate, enddate) :
    # companies_limit = 30

    q = paste ("select c.name
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
                 order by count(distinct(s.id)) desc"
                 # order by count(distinct(s.id)) desc LIMIT ", companies_limit
    query = new("Query", sql = q)
    data = run(query)	
    return (data)



def evol_info_data_companies (startdate, enddate) :
    # DEPRECATED FUNCTION; TO BE REMOVED	

	q = paste ("select count(distinct(c.id)) as companies 
                     from companies c,
                          upeople_companies upc,
                          people_upeople pup,
                          scmlog s
                     where c.id = upc.company_id and
                           upc.upeople_id = pup.upeople_id and
                           pup.people_id = s.author_id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, ";" 
	query = new("Query", sql = q)
	data13 = run(query)
	
	q = "select count(distinct(c.id)) as companies_2006
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
	query = new("Query", sql = q)
	data14 = run(query)
	
	q = "select count(distinct(c.id)) as companies_2009
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
	query = new("Query", sql = q)
	data15 = run(query)
	
	q = "select count(distinct(c.id)) as companies_2012
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
	query = new("Query", sql = q)
	data16 = run(query)
	
	
	agg_data = merge(data13, data14)
	agg_data = merge(agg_data, data15)
	agg_data = merge(agg_data, data16)
	return (agg_data)


def evol_info_data_countries (startdate, enddate) :
	
	q = paste ("select count(distinct(upc.country_id)) as countries
                     from upeople_countries upc,
                          people_upeople pup,
                          scmlog s
                     where upc.upeople_id = pup.upeople_id and
                           pup.people_id = s.author_id and
                           s.date >=", startdate, " and
                           s.date < ", enddate, ";" 
	query = new("Query", sql = q)
	data = run(query)
        return (data)

def company_top_authors (company_name, startdate, enddate) :
    # Returns top ten authors per company
 	
    q = paste ("select u.id as id, u.identifier  as authors,
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
                 limit 10;")
    query = new("Query", sql = q)
    data = run(query)
    return (data)

def company_top_authors_year (company_name, year):
    # Top 10 authors per company and in a given year
	
    q = paste ("select u.id as id, u.identifier as authors,
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
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def evol_companies (period, startdate, enddate):	
    # Evolution of companies, also deprecated function
	
    q = "select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
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
                group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")"
    query = new("Query", sql = q)
    data = run(query)
    return (data)	


def repos_name (startdate, enddate) :
    # List of repositories name

    q = paste ("select count(distinct(s.id)) as total, 
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
    query = new("Query", sql = q)
    data = run(query)
    return (data)	




# COUNTRIES support
def scm_countries_names (identities_db, startdate, enddate) :

    countries_limit = 30 
    rol = "author" #committer

    q = "SELECT count(s.id) as commits, c.name as name 
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
                order by commits desc LIMIT ", countries_limit
    query = new("Query", sql = q)
    data = run(query)	
    return (data)    




# Companies / Countries support

def scm_companies_countries_evol (identities_db, company, country, period, startdate, enddate) :

    rol = "author" #committer

    q = "SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
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
                GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")"
    query = new("Query", sql = q)
    data = run(query)	
    return (data)


# Domains
def evol_info_data_domains (startdate, enddate) :
    q = paste ("SELECT COUNT(DISTINCT(upd.domain_id)) AS domains
                    FROM upeople_domains upd,
                    people_upeople pup,
                    scmlog s
                    WHERE upd.upeople_id = pup.upeople_id AND
                    pup.people_id = s.author_id AND
                    s.date >=", startdate, " AND
                    s.date < ", enddate, ";"
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def scm_domains_names (identities_db, startdate, enddate) :

    rol = "author" #committer

    q = "SELECT count(s.id) as commits, d.name as name
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
                    ORDER BY commits desc"
    query = new("Query", sql = q)
    data = run(query)
    return (data)


##############
# Micro Studies
##############

def GetCodeCommunityStructure (period, startdate, enddate, identities_db):
  # This function provides information about the general structure of the community.
  # This is divided into core, regular and ocassional authors
  # Core developers are defined as those doing up to a 80% of the total commits
  # Regular developers are defind as those doing from the 80% to a 99% of the total commits
  # Occasional developers are defined as those doing from the 99% to the 100% of the commits

  # Init of structure to be returned
  community = numeric(0)
  community$core = numeric(1)
  community$regular = numeric(1)
  community$occasional = numeric(1)

  q = "select count(distinct(s.id))
                       from scmlog s, people p, actions a
                       where s.author_id = p.id and
                             p.email <> '%gerrit@%' and
                             p.email <> '%jenkins@%' and
                             s.id = a.commit_id and
                             s.date>=",startdate," and
                             s.date<=",enddate,";"
  query = new("Query", sql=q)
  total = run(query)
  total_commits = as.numeric(total)

  # Database access: developer, %commits
  q = " select pup.upeople_id,
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
               order by commits desc; "

  query = new("Query", sql=q)
  people = run(query)
  people$commits = (people$commits / total_commits) * 100

  # Calculating number of core, regular and occasional developers
  cont = 0
  core = 0
  core_f = TRUE # flag
  regular = 0
  regular_f = TRUE  # flag
  occasional = 0
  devs = 0

  for (value in people$commits):
    cont = cont + value
    devs = devs + 1

    if (core_f && cont >= 80):
      #core developers number reached
      core = devs
      core_f = FALSE

    if (regular_f && cont >= 95):
      regular = devs
      regular_f = FALSE

  occasional = devs - regular
  regular = regular - core

  # inserting values in variable
  community$core = core
  community$regular = regular
  community$occasional = occasional

  return(community)
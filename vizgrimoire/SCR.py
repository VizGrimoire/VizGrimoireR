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
## "*Changes" functions use changes table for more precisse results
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo San Felix <acs@bitergia.com>

from GrimoireSQL import GetSQLGlobal, GetSQLPeriod, GetSQLReportFrom
from GrimoireSQL import GetSQLReportWhere, ExecuteQuery, BuildQuery
from GrimoireUtils import GetPercentageDiff, GetDates, completePeriodIds
import GrimoireUtils

##########
# Specific FROM and WHERE clauses per type of report
##########
def GetSQLRepositoriesFromSCR ():
    #tables necessaries for repositories
    return (" , trackers t")


def GetSQLRepositoriesWhereSCR (repository):
    #fields necessaries to match info among tables
    return (" and t.url ='"+ repository+ "' and t.id = i.tracker_id")


def GetSQLCompaniesFromSCR (identities_db):
    #tables necessaries for companies
    return (" , people_upeople pup,"+\
            identities_db+".upeople_companies upc,"+\
            identities_db+".companies c")


def GetSQLCompaniesWhereSCR (company):
    #fields necessaries to match info among tables
    return ("and i.submitted_by = pup.people_id "+\
              "and pup.upeople_id = upc.upeople_id "+\
              "and i.submitted_on >= upc.init "+\
              "and i.submitted_on < upc.end "+\
              "and upc.company_id = c.id "+\
              "and c.name ='"+ company+"'")


def GetSQLCountriesFromSCR (identities_db):
    #tables necessaries for companies
    return (" , people_upeople pup, "+\
              identities_db+".upeople_countries upc, "+\
              identities_db+".countries c ")


def GetSQLCountriesWhereSCR (country):
    #fields necessaries to match info among tables
    return ("and i.submitted_by = pup.people_id "+\
              "and pup.upeople_id = upc.upeople_id "+\
              "and upc.country_id = c.id "+\
              "and c.name ='"+country+"'")


##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

def GetSQLReportFromSCR (identities_db, type_analysis):
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of
    #such analysis

    From = ""

    if (len(type_analysis) != 2): return From

    analysis = type_analysis[0]
    value = type_analysis[1]

    if (analysis):
        if analysis == 'repository': From = GetSQLRepositoriesFromSCR()
        elif analysis == 'company': From = GetSQLCompaniesFromSCR(identities_db)
        elif analysis == 'country': From = GetSQLCountriesFromSCR(identities_db)

    return (From)


def GetSQLReportWhereSCR (type_analysis):
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of
    #such analysis

    where = ""
    if (len(type_analysis) != 2): return where

    analysis = type_analysis[0]
    value = type_analysis[1]

    if (analysis):
        if analysis == 'repository': where = GetSQLRepositoriesWhereSCR(value)
        elif analysis == 'company': where = GetSQLCompaniesWhereSCR(value)
        elif analysis == 'country': where = GetSQLCountriesWhereSCR(value)

    return (where)


#########
# General functions
#########

def GetReposSCRName  (startdate, enddate, limit = 0):
    limit_sql=""
    if (limit > 0): limit_sql = " LIMIT " + str(limit)

    q = "SELECT t.url as name, COUNT(DISTINCT(i.id)) AS issues "+\
           " FROM  issues i, trackers t "+\
           " WHERE i.tracker_id = t.id AND "+\
           "  i.submitted_on >="+  startdate+ " AND "+\
           "  i.submitted_on < "+ enddate +\
           " GROUP BY t.url "+\
           " ORDER BY issues DESC "+limit_sql
    return(ExecuteQuery(q))

def GetCompaniesSCRName  (startdate, enddate, identities_db, limit = 0):
    limit_sql=""
    if (limit > 0): limit_sql = " LIMIT " + str(limit)

    q = "SELECT c.id as id, c.name as name, COUNT(DISTINCT(i.id)) AS total "+\
               "FROM  "+identities_db+".companies c, "+\
                       identities_db+".upeople_companies upc, "+\
                "     people_upeople pup, "+\
                "     issues i "+\
               "WHERE i.submitted_by = pup.people_id AND "+\
               "  upc.upeople_id = pup.upeople_id AND "+\
               "  c.id = upc.company_id AND "+\
               "  i.status = 'merged' AND "+\
               "  i.submitted_on >="+  startdate+ " AND "+\
               "  i.submitted_on < "+ enddate+ " "+\
               "GROUP BY c.name "+\
               "ORDER BY total DESC " + limit_sql
    return(ExecuteQuery(q))

def GetCountriesSCRName  (startdate, enddate, identities_db, limit = 0):
    limit_sql=""
    if (limit > 0): limit_sql = " LIMIT " + str(limit)

    q = "SELECT c.name as name, COUNT(DISTINCT(i.id)) AS issues "+\
           "FROM  "+identities_db+".countries c, "+\
                   identities_db+".upeople_countries upc, "+\
            "    people_upeople pup, "+\
            "    issues i "+\
           "WHERE i.submitted_by = pup.people_id AND "+\
           "  upc.upeople_id = pup.upeople_id AND "+\
           "  c.id = upc.country_id AND "+\
           "  i.status = 'merged' AND "+\
           "  i.submitted_on >="+  startdate+ " AND "+\
           "  i.submitted_on < "+ enddate+ " "+\
           "GROUP BY c.name "+\
           "ORDER BY issues DESC "+limit_sql
    return(ExecuteQuery(q))

#########
#Functions about the status of the review
#########

# REVIEWS
def GetReviews (period, startdate, enddate, type, type_analysis, evolutionary, identities_db):

    #Building the query
    fields = " count(distinct(i.issue)) as " + type
    tables = "issues i" + GetSQLReportFromSCR(identities_db, type_analysis)
    if type == "submitted": filters = ""
    elif type == "opened": filters = " (i.status = 'NEW' or i.status = 'WORKINPROGRESS') "
    elif type == "new": filters = " i.status = 'NEW' "
    elif type == "inprogress": filters = " i.status = 'WORKINGPROGRESS' "
    elif type == "closed": filters = " (i.status = 'MERGED' or i.status = 'ABANDONED') "
    elif type == "merged": filters = " i.status = 'MERGED' "
    elif type == "abandoned": filters = " i.status = 'ABANDONED' "
    filters = filters + GetSQLReportWhereSCR(type_analysis)

    #Adding dates filters (and evolutionary or static analysis)
    if (evolutionary):
        q = GetSQLPeriod(period, "i.submitted_on", fields, tables, filters,
                      startdate, enddate)
    else:
        q = GetSQLGlobal(" i.submitted_on ", fields, tables, filters, startdate, enddate)

    return(ExecuteQuery(q))


# Reviews status using changes table
def GetReviewsChanges(period, startdate, enddate, type, type_analysis, evolutionary, identities_db):
    fields = "count(issue_id) as "+ type+ "_changes"
    tables = "changes c, issues i"
    tables = tables + GetSQLReportFromSCR(identities_db, type_analysis)
    filters = "c.issue_id = i.id AND new_value='"+type+"'"
    filters = filters + GetSQLReportWhereSCR(type_analysis)

    #Adding dates filters (and evolutionary or static analysis)
    if (evolutionary):
        q = GetSQLPeriod(period, " changed_on", fields, tables, filters,
                            startdate, enddate)
    else:
        q = GetSQLGlobal(" changed_on ", fields, tables, filters, startdate, enddate)

    return(ExecuteQuery(q))


# EVOLUTIONoneRY META FUNCTIONS BASED ON REVIEWS

def EvolReviewsSubmitted (period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, True, identities_db))

def EvolReviewsOpened (period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, True, identities_db))

def EvolReviewsNew(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "new", type_analysis, True, identities_db))

def GetEvolChanges(period, startdate, enddate, value):
    fields = "count(issue_id) as "+ value+ "_changes"
    tables = "changes"
    filters = "new_value='"+value+"'"
    q = GetSQLPeriod(period, " changed_on", fields, tables, filters,
            startdate, enddate)
    return(ExecuteQuery(q))

def EvolReviewsNewChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "new", type_analysis, True, identities_db))

def EvolReviewsInProgress(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, True, identities_db))

def EvolReviewsClosed(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, True, identities_db))

def EvolReviewsMerged(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, True, identities_db))

def EvolReviewsMergedChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "merged", type_analysis, True, identities_db))

def EvolReviewsAbandoned(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, True, identities_db))


def EvolReviewsAbandonedChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "abandoned", type_analysis, True, identities_db))


def EvolReviewsPending(period, startdate, enddate, config, type_analysis = [], identities_db=None):
    data = EvolReviewsSubmitted(period, startdate, enddate, type_analysis, identities_db)
    data = completePeriodIds(data)
    data1 = EvolReviewsMerged(period, startdate, enddate, type_analysis, identities_db)
    data1 = completePeriodIds(data1)
    data2 = EvolReviewsAbandoned(period, startdate, enddate, type_analysis, identities_db)
    data2 = completePeriodIds(data2)
    evol = dict(data.items() + data1.items() + data2.items())
    pending = {"pending":[]}

    for i in range(0, len(data['merged'])):
        pending_val = evol["submitted"][i] - evol["merged"][i] - evol["abandoned"][i]
        pending["pending"].append(pending_val)
    pending = completePeriodIds(pending)
    return pending

# PENDING = SUBMITTED - MERGED - ABANDONED
def EvolReviewsPendingChanges(period, startdate, enddate, config, type_analysis = [], identities_db=None):
    data = EvolReviewsSubmitted(period, startdate, enddate, type_analysis, identities_db)
    data = completePeriodIds(data)
    data1 = EvolReviewsMergedChanges(period, startdate, enddate, type_analysis, identities_db)
    data1 = completePeriodIds(data1)
    data2 = EvolReviewsAbandonedChanges(period, startdate, enddate, type_analysis, identities_db)
    data2 = completePeriodIds(data2)
    evol = dict(data.items() + data1.items() + data2.items())
    pending = {"pending":[]}

    for i in range(0,len(evol['merged_changes'])):
        pending_val = evol["submitted"][i] - evol["merged_changes"][i] - evol["abandoned_changes"][i]
        pending["pending"].append(pending_val)
    pending["month"] = evol["month"]
    pending = completePeriodIds(pending)
    return pending

# STATIC META FUNCTIONS BASED ON REVIEWS

def StaticReviewsSubmitted (period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "submitted", type_analysis, False, identities_db))


def StaticReviewsOpened (period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "opened", type_analysis, False, identities_db))


def StaticReviewsNew(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "new", type_analysis, False, identities_db))


def StaticReviewsNewChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "new", False))


def StaticReviewsInProgress(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "inprogress", type_analysis, False, identities_db))


def StaticReviewsClosed(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "closed", type_analysis, False, identities_db))


def StaticReviewsMerged(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "merged", type_analysis, False, identities_db))


def StaticReviewsMergedChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "merged", False))


def StaticReviewsAbandoned(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviews(period, startdate, enddate, "abandoned", type_analysis, False, identities_db))


def StaticReviewsAbandonedChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    return (GetReviewsChanges(period, startdate, enddate, "abandoned", False))


# PENDING = SUBMITTED - MERGED - ABANDONED
def StaticReviewsPending(period, startdate, enddate, type_analysis = [], identities_db=None):
    submitted = StaticReviewsSubmitted(period, startdate, enddate, type_analysis, identities_db)
    merged = StaticReviewsMerged(period, startdate, enddate, type_analysis, identities_db)
    abandoned = StaticReviewsAbandoned(period, startdate, enddate, type_analysis, identities_db)
    pending = submitted['submitted']-merged['merged']-abandoned['abandoned']
    return ({"pending":pending})


def StaticReviewsPendingChanges(period, startdate, enddate, type_analysis = [], identities_db=None):
    submitted = StaticReviewsSubmitted(period, startdate, enddate, type_analysis, identities_db)
    merged = StaticReviewsMergedChanges(period, startdate, enddate, type_analysis, identities_db)
    abandoned = StaticReviewsAbandonedChanges(period, startdate, enddate, type_analysis, identities_db)
    pending = submitted['submitted']-merged['merged']-abandoned['abandoned']
    return ({"pending":pending})


#WORK ON PATCHES: ANY REVIEW MAY HAVE MORE THAN ONE PATCH
def GetEvaluations (period, startdate, enddate, type, type_analysis, evolutionary):
    # verified - VRIF
    # approved - APRV
    # code review - CRVW
    # submitted - SUBM

    #Building the query
    fields = " count(distinct(c.id)) as " + type
    tables = " changes c, issues i " + GetSQLReportFromSCR(None, type_analysis)
    if type == "verified": filters =  " (c.field = 'VRIF' OR c.field = 'Verified') "
    elif type == "approved": filters =  " c.field = 'APRV'  "
    elif type == "codereview": filters =  "   (c.field = 'CRVW' OR c.field = 'Code-Review') "
    elif type == "sent": filters =  " c.field = 'SUBM'  "
    filters = filters + " and i.id = c.issue_id "
    filters = filters + GetSQLReportWhereSCR(type_analysis)

    #Adding dates filters
    if (evolutionary):
        q = GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                          startdate, enddate)
    else:
        q = GetSQLGlobal(" c.changed_on", fields, tables, filters,
                      startdate, enddate)
    return(ExecuteQuery(q))

# EVOLUTIONoneRY METRICS
def EvolPatchesVerified (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "verified", type_analysis, True))


def EvolPatchesApproved (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "approved", type_analysis, True))


def EvolPatchesCodeReview (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "codereview", type_analysis, True))


def EvolPatchesSent (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "sent", type_analysis, True))


#STATIC METRICS
def StaticPatchesVerified  (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "verified", type_analysis, False))


def StaticPatchesApproved (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "approved", type_analysis, False))


def StaticPatchesCodeReview (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "codereview", type_analysis, False))


def StaticPatchesSent (period, startdate, enddate, type_analysis = []):
    return (GetEvaluations (period, startdate, enddate, "sent", type_analysis, False))


#PATCHES WAITING FOR REVIEW FROM REVIEWER
def GetWaiting4Reviewer (period, startdate, enddate, identities_db, type_analysis, evolutionary):
     fields = " count(distinct(c.id)) as WaitingForReviewer "
     tables = " changes c, "+\
              "  issues i, "+\
              "        (select c.issue_id as issue_id, "+\
              "                c.old_value as old_value, "+\
              "                max(c.id) as id "+\
              "         from changes c, "+\
              "              issues i "+\
              "         where c.issue_id = i.id and "+\
              "               i.status='NEW' "+\
              "         group by c.issue_id, c.old_value) t1 "
     tables = tables + GetSQLReportFromSCR(identities_db, type_analysis)
     filters =  " i.id = c.issue_id  "+\
                "  and t1.id = c.id "+\
                "  and (c.field='CRVW' or c.field='Code-Review' or c.field='Verified' or c.field='VRIF') "+\
                "  and (c.new_value=1 or c.new_value=2) "
     filters = filters + GetSQLReportWhereSCR(type_analysis)

     if (evolutionary):
         q = GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                           startdate, enddate)
     else:
         q = GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                           startdate, enddate)

     return(ExecuteQuery(q))


def EvolWaiting4Reviewer (period, startdate, enddate, identities_db=None, type_analysis = []):
    return (GetWaiting4Reviewer(period, startdate, enddate, identities_db, type_analysis, True))


def StaticWaiting4Reviewer (period, startdate, enddate, identities_db=None, type_analysis = []):
    return (GetWaiting4Reviewer(period, startdate, enddate, identities_db, type_analysis, False))


def GetWaiting4Submitter (period, startdate, enddate, identities_db, type_analysis, evolutionary):

     fields = "count(distinct(c.id)) as WaitingForSubmitter "
     tables = "  changes c, "+\
              "   issues i, "+\
              "        (select c.issue_id as issue_id, "+\
              "                c.old_value as old_value, "+\
              "                max(c.id) as id "+\
              "         from changes c, "+\
              "              issues i "+\
              "         where c.issue_id = i.id and "+\
              "               i.status='NEW' "+\
              "         group by c.issue_id, c.old_value) t1 "
     tables = tables + GetSQLReportFromSCR(identities_db, type_analysis)
     filters = " i.id = c.issue_id "+\
               "  and t1.id = c.id "+\
	           "  and (c.field='CRVW' or c.field='Code-Review' or c.field='Verified' or c.field='VRIF') "+\
               "  and (c.new_value=-1 or c.new_value=-2) "
     filters = filters + GetSQLReportWhereSCR(type_analysis)

     if (evolutionary):
         q = GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                           startdate, enddate)
     else:
         q = GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                           startdate, enddate)


     return(ExecuteQuery(q))


def EvolWaiting4Submitter (period, startdate, enddate, identities_db=None, type_analysis = []):
    return (GetWaiting4Submitter(period, startdate, enddate, identities_db, type_analysis, True))


def StaticWaiting4Submitter (period, startdate, enddate, identities_db=None, type_analysis = []):
    return (GetWaiting4Submitter(period, startdate, enddate, identities_db, type_analysis, False))


#REVIEWERS

def GetReviewers (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    # TODO: so far without unique identities

    fields = " count(distinct(changed_by)) as reviewers "
    tables = " changes c "
    filters = ""

    if (evolutionary):
        q = GetSQLPeriod(period, " c.changed_on", fields, tables, filters,
                          startdate, enddate)
    else:
        q = GetSQLGlobal(" c.changed_on ", fields, tables, filters,
                          startdate, enddate)
    return(ExecuteQuery(q))


def EvolReviewers  (period, startdate, enddate, identities_db=None, type_analysis = []):
    return (GetReviewers(period, startdate, enddate, identities_db, type_analysis, True))


def StaticReviewers  (period, startdate, enddate, identities_db = None, type_analysis = []):
    return (GetReviewers(period, startdate, enddate, identities_db, type_analysis, False))


def GetLongestReviews  (startdate, enddate, type_analysis = []):

    q = "select i.issue as review, "+\
        "         t1.old_value as patch, "+\
        "         timestampdiff (HOUR, t1.min_time, t1.max_time) as timeOpened "+\
        "  from ( "+\
        "        select c.issue_id as issue_id, "+\
        "               c.old_value as old_value, "+\
        "               min(c.changed_on) as min_time, "+\
        "               max(c.changed_on) as max_time "+\
        "        from changes c, "+\
        "             issues i "+\
        "        where c.issue_id = i.id and "+\
        "              i.status='NEW' "+\
        "        group by c.issue_id, "+\
        "                 c.old_value) t1, "+\
        "       issues i "+\
        "  where t1.issue_id = i.id "+\
        "  order by timeOpened desc "+\
        "  limit 20"
    fields = " i.issue as review, " + \
             " t1.old_value as patch, " + \
            " timestampdiff (HOUR, t1.min_time, t1.max_time) as timeOpened, "
    tables = " issues i, "+\
            " (select c.issue_id as issue_id, "+\
            "           c.old_value as old_value, "+\
            "           min(c.changed_on) as min_time, "+\
            "           max(c.changed_on) as max_time "+\
            "    from changes c, "+\
            "         issues i "+\
            "    where c.issue_id = i.id and "+\
            "          i.status='NEW' "+\
            "    group by c.issue_id, "+\
            "             c.old_value) t1 "
    tables = tables + GetSQLReportFromSCR(identities_db, type_analysis)
    filters = " t1.issue_id = i.id "
    filters = filters + GetSQLReportWhereSCR(type_analysis)

    q = GetSQLGlobal(" i.submitted_on ", fields, tables, filters,
                           startdate, enddate)

    return(ExecuteQuery(q))

##
# Tops
##

# Is this right???
def GetTopReviewersSCR (days, startdate, enddate, identities_db, bots, limit):
    date_limit = ""
    filter_bots = ''
    for bot in bots:
        filter_bots = filter_bots + " up.identifier<>'"+bot+"' and "

    if (days != 0 ):
        q = "SELECT @maxdate:=max(changed_on) from changes limit 1"
        ExecuteQuery(q)
        date_limit = " AND DATEDIFF(@maxdate, changed_on)<" + str(days)

    q = "SELECT up.id as id, up.identifier as reviewers, "+\
        "               count(distinct(c.id)) as reviewed "+\
        "        FROM people_upeople pup, changes c, "+ identities_db+".upeople up "+\
        "        WHERE "+ filter_bots+ " "+\
        "            c.changed_by = pup.people_id and "+\
        "            pup.upeople_id = up.id and "+\
        "            c.changed_on >= "+ startdate + " and "+\
        "            c.changed_on < "+ enddate + " "+\
        "            "+ date_limit + " "+\
        "        GROUP BY up.identifier "+\
        "        ORDER BY reviewed desc, reviewers "+\
        "        LIMIT " + limit
    return(ExecuteQuery(q))


def GetTopSubmittersQuerySCR   (days, startdate, enddate, identities_db, bots, limit, merged = False):
    date_limit = ""
    merged_sql = ""
    rol = "openers"
    action = "opened"
    filter_bots = ''
    for bot in bots:
        filter_bots = filter_bots+ " up.identifier<>'"+bot+"' and "

    if (days != 0 ):
        q = "SELECT @maxdate:=max(submitted_on) from issues limit 1"
        ExecuteQuery(q)
        date_limit = " AND DATEDIFF(@maxdate, submitted_on)<"+str(days)

    if (merged):
        merged_sql = " AND status='MERGED' "
        rol = "mergers"
        action = "merged"


    q = "SELECT up.id as id, up.identifier as "+rol+", "+\
        "            count(distinct(i.id)) as "+action+" "+\
        "        FROM people_upeople pup, issues i, "+identities_db+".upeople up "+\
        "        WHERE "+ filter_bots+ " "+\
        "            i.submitted_by = pup.people_id and "+\
        "            pup.upeople_id = up.id and "+\
        "            i.submitted_on >= "+ startdate+ " and "+\
        "            i.submitted_on < "+ enddate+ " "+\
        "            "+date_limit+ merged_sql+ " "+\
        "        GROUP BY up.identifier "+\
        "        ORDER BY "+action+" desc, id "+\
        "        LIMIT "+ limit
    return(q)


def GetTopOpenersSCR (days, startdate, enddate, identities_db, bots, limit):
    q = GetTopSubmittersQuerySCR (days, startdate, enddate, identities_db, bots, limit)
    return(ExecuteQuery(q))


def GetTopMergersSCR   (days, startdate, enddate, identities_db, bots, limit):
    q = GetTopSubmittersQuerySCR (days, startdate, enddate, identities_db, bots, limit, True)
    return(ExecuteQuery(q))


#########
# PEOPLE: Pretty similar to ITS
#########
def GetTablesOwnUniqueIdsSCR (table=''):
    tables = 'changes c, people_upeople pup'
    if (table == "issues"): tables = 'issues i, people_upeople pup'
    return (tables)


def GetFiltersOwnUniqueIdsSCR  (table=''):
    filters = 'pup.people_id = c.changed_by'
    if (table == "issues"): filters = 'pup.people_id = i.submitted_by'
    return (filters)


def GetPeopleListSCR (startdate, enddate, bots):

    filter_bots = ""
    for bot in bots:
        filter_bots += " name<>'"+bot+"' and "

    fields = "DISTINCT(pup.upeople_id) as id, count(i.id) as total, name"
    tables = GetTablesOwnUniqueIdsSCR('issues') + ", people"
    filters = filter_bots
    filters += GetFiltersOwnUniqueIdsSCR('issues')+ " and people.id = pup.people_id"
    filters += " GROUP BY id ORDER BY total desc"
    q = GetSQLGlobal('submitted_on', fields, tables, filters, startdate, enddate)
    print(q)
    return(ExecuteQuery(q))


def GetPeopleQuerySCR (developer_id, period, startdate, enddate, evol):
    fields = "COUNT(c.id) AS closed"
    tables = GetTablesOwnUniqueIdsSCR()
    filters = GetFiltersOwnUniqueIdsSCR()+ " AND pup.upeople_id = "+ str(developer_id)

    if (evol):
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters,
                startdate, enddate)
    else:
        fields = fields + \
                ",DATE_FORMAT (min(changed_on),'%Y-%m-%d') as first_date, "+\
                "  DATE_FORMAT (max(changed_on),'%Y-%m-%d') as last_date"
        q = GetSQLGlobal('changed_on', fields, tables, filters,
                startdate, enddate)
    return (q)


def GetPeopleEvolSCR (developer_id, period, startdate, enddate):
    q = GetPeopleQuerySCR(developer_id, period, startdate, enddate, True)
    return(ExecuteQuery(q))

def GetPeopleStaticSCR (developer_id, startdate, enddate):
    q = GetPeopleQuerySCR(developer_id, None, startdate, enddate, False)
    return(ExecuteQuery(q))

################
# Time to review
################

def GetTimeToReviewQuerySCR (startdate, enddate, identities_db = None, type_analysis = []):
    # Subquery to get the time to review for all reviews
    fields = "DATEDIFF(changed_on,submitted_on) AS revtime, changed_on "
    tables = "issues i, changes "
    tables = tables + GetSQLReportFromSCR(identities_db, type_analysis)
    filters = "i.id = changes.issue_id AND field='status' "
    filters = filters+ GetSQLReportWhereSCR(type_analysis)
    filters = filters+ " AND new_value='MERGED' "
    q = GetSQLGlobal('changed_on', fields, tables, filters,
                    startdate, enddate)
    return (q)


def EvolTimeToReviewSCR (period, startdate, enddate, identities_db = None, type_analysis = []):
    q = GetTimeToReviewQuerySCR (startdate, enddate, identities_db, type_analysis)
    # Evolution in time of AVG review time
    fields = "SUM(revtime)/COUNT(revtime) AS review_time_days_avg "
    tables = "("+q+") t"
    filters = ""
    q = GetSQLPeriod(period,'changed_on', fields, tables, filters,
            startdate, enddate)
    data = ExecuteQuery(q)
    if not isinstance(data['review_time_days_avg'], (list)): 
        data['review_time_days_avg'] = [data['review_time_days_avg']]
    return(data)

def StaticTimeToReviewSCR (startdate, enddate, identities_db = None, type_analysis = []):
    q = GetTimeToReviewQuerySCR (startdate, enddate, identities_db, type_analysis)
    # Total AVG review time
    q = " SELECT AVG(revtime) AS review_time_days_avg FROM ("+q+") t"
    return(ExecuteQuery(q))

##############
# Microstudies
##############

def GetSCRDiffSubmittedDays (period, init_date, days,
        identities_db=None, type_analysis = []):
    chardates = GetDates(init_date, days)
    last = StaticReviewsSubmitted(period, chardates[1], chardates[0])
    last = int(last['submitted'])
    prev = StaticReviewsSubmitted(period, chardates[2], chardates[1])
    prev = int(prev['submitted'])

    data = {}
    data['diff_netsubmitted_'+str(days)] = last - prev
    data['percentage_submitted_'+str(days)] = GetPercentageDiff(prev, last)
    data['submitted_'+str(days)] = last
    return (data)

def GetSCRDiffMergedDays (period, init_date, days,
        identities_db=None, type_analysis = []):

    chardates = GetDates(init_date, days)
    last = StaticReviewsMerged(period, chardates[1], chardates[0])
    last = int(last['merged'])
    prev = StaticReviewsMerged(period, chardates[2], chardates[1])
    prev = int(prev['merged'])

    data = {}
    data['diff_netmerged_'+str(days)] = last - prev
    data['percentage_merged_'+str(days)] = GetPercentageDiff(prev, last)
    data['merged_'+str(days)] = last
    return (data)

def GetSCRDiffAbandonedDays (period, init_date, days,
        identities_db=None, type_analysis = []):

    chardates = GetDates(init_date, days)
    last = StaticReviewsAbandoned(period, chardates[1], chardates[0])
    last = int(last['abandoned'])
    prev = StaticReviewsAbandoned(period, chardates[2], chardates[1])
    prev = int(prev['abandoned'])

    data = {}
    data['diff_netabandoned_'+str(days)] = last - prev
    data['percentage_abandoned_'+str(days)] = GetPercentageDiff(prev, last)
    data['abandoned_'+str(days)] = last
    return (data)


def GetSCRDiffPendingDays (period, init_date, days,
        identities_db=None, type_analysis = []):

    chardates = GetDates(init_date, days)
    last = StaticReviewsPending(period, chardates[1], chardates[0])
    last = int(last['pending'])
    prev = StaticReviewsPending(period, chardates[2], chardates[1])
    prev = int(prev['pending'])

    data = {}
    data['diff_netpending_'+str(days)] = last - prev
    data['percentage_pending_'+str(days)] = GetPercentageDiff(prev, last)
    data['pending_'+str(days)] = last
    return (data)

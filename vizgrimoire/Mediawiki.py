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
## MediaWiki.R
##
## Queries for source code review data analysis
##
## Authors:
##   Alvaro del Castillo <acs@bitergia.com>

from GrimoireSQL import GetSQLGlobal, GetSQLPeriod, GetSQLReportFrom 
from GrimoireSQL import GetSQLReportWhere, ExecuteQuery, BuildQuery
from GrimoireUtils import GetPercentageDiff, GetDates, completePeriodIds
import GrimoireUtils


# SQL Metaqueries

def GetTablesOwnUniqueIdsMediaWiki () :
    tables = 'wiki_pages_revs, people_upeople pup'
    return (tables)


def GetFiltersOwnUniqueIdsMediaWiki () :
    filters = 'pup.people_id = wiki_pages_revs.user'
    return (filters) 


# GLOBAL

def GetStaticDataMediaWiki (period, startdate, enddate, i_db, type_analysis):
    reviews = StaticNumReviewsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    authors = StaticNumAuthorsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    pages = StaticPagesMediaWiki(period, startdate, enddate, i_db, type_analysis)

    agg = dict(reviews.items() + authors.items() + pages.items())

    return (agg)


def GetEvolDataMediaWiki (period, startdate, enddate, i_db, type_analysis):

    # 1- Retrieving information
    reviews = completePeriodIds(EvolReviewsMediaWiki(period, startdate, enddate, i_db, type_analysis))
    authors =completePeriodIds( EvolAuthorsMediaWiki(period, startdate, enddate, i_db, type_analysis))
    pages = completePeriodIds(EvolPagesMediaWiki(period, startdate, enddate, i_db, type_analysis))

    # 2- Merging information
    evol_data = dict(reviews.items()+ authors.items() + pages.items())

    return (evol_data)


def StaticNumReviewsMediaWiki (period, startdate, enddate, identities_db, type_analysis) :    
    select = "SELECT count(rev_id) as reviews, "+\
               "DATE_FORMAT (min(date), '%Y-%m-%d') as first_date, "+\
               "DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    tables = " FROM wiki_pages_revs "
    where = " where date >=" + startdate + " and date < "+ enddate
    q = select + tables + where
    return(ExecuteQuery(q))


def StaticNumAuthorsMediaWiki (period, startdate, enddate, identities_db, type_analysis) :    
    select = "SELECT count(distinct(user)) as authors"
    tables = " FROM wiki_pages_revs "
    where = " where date >="+ startdate + " and date < "+ enddate
    q = select + tables + where
    return(ExecuteQuery(q))

def GetQueryPagesMediaWiki (period, startdate, enddate, evol) :
    fields = "COUNT(page_id) as pages"
    tables = " ( "+\
            "SELECT wiki_pages.page_id, MIN(date) as date FROM wiki_pages, wiki_pages_revs "+\
            "WHERE wiki_pages.page_id=wiki_pages_revs.page_id  "+\
            "GROUP BY wiki_pages.page_id) t "
    filters = ''

    if (evol) :
            q = GetSQLPeriod(period,'date', fields, tables, filters,
                            startdate, enddate)
    else :
            q = GetSQLGlobal('date', fields, tables, filters,
                            startdate, enddate)
    return(q)

def StaticPagesMediaWiki (period, startdate, enddate, identities_db, type_analysis) :
    q = GetQueryPagesMediaWiki(period, startdate, enddate, False)

    data = ExecuteQuery(q)
    return (data)


def EvolPagesMediaWiki (period, startdate, enddate, identities_db, type_analysis) :
    q = GetQueryPagesMediaWiki(period, startdate, enddate, True)

    data = ExecuteQuery(q)
    return (data)


def GetReviewsMediaWiki (period, startdate, enddate, identities_db, type_analysis, evolutionary):    
    fields = " count(distinct(rev_id)) as reviews "
    tables = " wiki_pages_revs " + GetSQLReportFrom(identities_db, type_analysis)
    filters = GetSQLReportWhere(type_analysis, "author")
    q = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))


def EvolReviewsMediaWiki (period, startdate, enddate, identities_db, type_analysis):
    return(GetReviewsMediaWiki(period, startdate, enddate, identities_db, type_analysis, True))


def GetAuthorsMediaWiki (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    fields = " count(distinct(user)) as authors "
    tables = " wiki_pages_revs " + GetSQLReportFrom(identities_db, type_analysis)
    filters = GetSQLReportWhere(type_analysis, "author")
    q = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))


def EvolAuthorsMediaWiki (period, startdate, enddate, identities_db, type_analysis):
    return(GetAuthorsMediaWiki(period, startdate, enddate, identities_db, type_analysis, True))


def GetTopAuthorsMediaWiki (days, startdate, enddate, identities_db, bots, limit) :
    date_limit = ""
    filter_bots = ''
    for bot in bots:
        filter_bots += " user<>'"+bot+"' and "

    if (days != 0 ) :
        ExecuteQuery("SELECT @maxdate:=max(date) from wiki_pages_revs limit 1")
        date_limit = " AND DATEDIFF(@maxdate, date)<"+str(days)

    q = "SELECT up.id as id, up.identifier as authors, "+\
        "    count(wiki_pages_revs.id) as reviews "+\
        "FROM wiki_pages_revs, people_upeople pup, "+identities_db+".upeople up "+\
        "WHERE "+ filter_bots+ " "+\
        "    wiki_pages_revs.user = pup.people_id and "+\
        "    pup.upeople_id = up.id and "+\
        "    date >= "+ startdate+ " and "+\
        "    date  < "+ enddate+ " "+ date_limit+ " "+\
        "    GROUP BY authors "+\
        "    ORDER BY reviews desc, authors "+\
        "    LIMIT "+ limit

    data = ExecuteQuery(q)
    return (data)


#########
# PEOPLE
#########
def GetListPeopleMediaWiki (startdate, enddate) :
    fields = "DISTINCT(pup.upeople_id) as id, count(wiki_pages_revs.id) total"
    tables = GetTablesOwnUniqueIdsMediaWiki()
    filters = GetFiltersOwnUniqueIdsMediaWiki()
    filters += " GROUP BY user ORDER BY total desc"
    q = GetSQLGlobal('date',fields,tables, filters, startdate, enddate)

    data = ExecuteQuery(q)
    return (data)


def GetQueryPeopleMediaWiki (developer_id, period, startdate, enddate, evol) :
    fields = "COUNT(wiki_pages_revs.id) AS revisions"
    tables = GetTablesOwnUniqueIdsMediaWiki()
    filters = GetFiltersOwnUniqueIdsMediaWiki() + " AND pup.upeople_id = " + str(developer_id)

    if (evol) :
        q = GetSQLPeriod(period,'date', fields, tables, filters,
                startdate, enddate)
    else :
        fields += ",DATE_FORMAT (min(date),'%Y-%m-%d') as first_date, "+\
                  "DATE_FORMAT (max(date),'%Y-%m-%d') as last_date"
        q = GetSQLGlobal('date', fields, tables, filters,
                startdate, enddate)
    return (q)


def GetEvolPeopleMediaWiki (developer_id, period, startdate, enddate) :
    q = GetQueryPeopleMediaWiki(developer_id, period, startdate, enddate, True)

    data = ExecuteQuery(q)
    return (data)


def GetStaticPeopleMediaWiki (developer_id, startdate, enddate) :
    q = GetQueryPeopleMediaWiki(developer_id, None, startdate, enddate, False)

    data = ExecuteQuery(q)
    return (data)



###############
# Last Activity
###############
def lastActivityMediaWiki (init_date, days) :
    #commits
    days = str(days)
    q = "select count(wiki_pages_revs.id) as reviews_"+days+" "+\
        "from wiki_pages_revs "+\
        "where date >= ("+ init_date+ " - INTERVAL "+days+" day)"


    data1 = ExecuteQuery(q)
    q = "select count(distinct(pup.upeople_id)) as authors_"+days+" "+\
        "from wiki_pages_revs, people_upeople pup "+\
        "where pup.people_id = user  and "+\
        "  date >= ("+ init_date+ " - INTERVAL "+days+" day)"


    data2 = ExecuteQuery(q)

    agg_data = dict(data1.items() + data2.items())

    return(agg_data)


##############
# Microstudies
##############

def GetMediaWikiDiffReviewsDays (period, date, identities_db, days):
    # This function provides the percentage in activity between two periods.
    #
    # The netvalue indicates if this is an increment (positive value) or decrement (negative value)

    chardates = GetDates(date, days)
    last = StaticNumReviewsMediaWiki(period, chardates[1], chardates[0], identities_db, None)
    last = int(last['reviews'])
    prev = StaticNumReviewsMediaWiki(period, chardates[2], chardates[1], identities_db, None)
    prev = int(prev['reviews'])

    data = {}
    data['diff_netreviews_'+str(days)] = last - prev
    data['percentage_reviews_'+str(days)] = GetPercentageDiff(prev, last)
    data['reviews_'+str(days)] = last

    return (data)

def GetMediaWikiDiffAuthorsDays (period, date, identities_db, days):
    chardates = GetDates(date, days)
    last = StaticNumAuthorsMediaWiki(period, chardates[1], chardates[0], identities_db, None)
    last = int(last['authors'])
    prev = StaticNumAuthorsMediaWiki(period, chardates[2], chardates[1], identities_db, None)
    prev = int(prev['authors'])

    data = {}
    data['diff_netauthors_'+str(days)] = last - prev
    data['percentage_authors_'+str(days)] = GetPercentageDiff(prev, last)
    data['authors_'+str(days)] = last

    return (data)

#!/usr/bin/env python

# Copyright (C) 2014 Bitergia
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# This file is a part of the vizGrimoire.R package
#
# Authors:
#     Alvaro del Castillo <acs@bitergia.com>
#     Daniel Izquierdo <dizquierdo@bitergia.com>

from GrimoireSQL import GetSQLGlobal, GetSQLPeriod, GetSQLReportFrom
from GrimoireSQL import GetSQLReportWhere, ExecuteQuery, BuildQuery
from GrimoireUtils import GetPercentageDiff, GetDates
import GrimoireUtils

# SQL Metaqueries
def GetIRCSQLRepositoriesFrom ():
    # tables necessary for repositories
    return (", channels c")


def GetIRCSQLRepositoriesWhere (repository):
    # filters necessaries for repositories
    return (" i.channel_id = c.id and c.name="+repository+" ")


def GetIRCSQLCompaniesFrom (i_db):
    # tables necessary to companies analysis
    return(" , people_upeople pup, "+\
                   i_db+"companies c, "+\
                   i_db+".upeople_companies upc")


def GetIRCSQLCompaniesWhere (name):
    # filters necessary to companies analysis
    return(" i.nick = pup.people_id and "+\
           "pup.upeople_id = upc.upeople_id and "+\
           "upc.company_id = c.id and "+\
           "i.submitted_on >= upc.init and "+\
           "i.submitted_on < upc.end and "+\
           "c.name = "+name)


def GetIRCSQLCountriesFrom (i_db):
    # tables necessary to countries analysis
    return(" , people_upeople pup, "+\
           i_db+".countries c, "+\
           i_db+".upeople_countries upc")


def GetIRCSQLCcountriesWhere (name):
    # filters necessary to countries analysis
    return(" i.nick = pup.people_id and "+\
           "pup.upeople_id = upc.upeople_id and "+\
           "upc.country_id = c.id and "+\
           "c.name = "+name)


def GetIRCSQLDomainsFrom (i_db):
    # tables necessary to domains analysis
    return(" , people_upeople pup, "+\
           i_db+".domains d, "+\
           i_db+".upeople_domains upd")



def GetIRCSQLDomainsWhere ():
    # filters necessary to domains analysis
    return(" i.nick = pup.people_id and "+\
           "pup.upeople_id = upd.upeople_id and "+\
           "upd.domain_id = d.id and "+\
           "d.name = "+name)

def GetTablesOwnUniqueIdsIRC () :
    tables = 'irclog, people_upeople pup'
    return (tables)

def GetFiltersOwnUniqueIdsIRC () :
    filters = 'pup.people_id = irclog.nick'
    return (filters) 

##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

def GetIRCSQLReportFrom (identities_db, type_analysis):
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    From = ""

    if (len(type_analysis) != 2): return From

    analysis = type_analysis[0]
    value = type_analysis[1]

    if analysis == 'repository': From = GetIRCSQLRepositoriesFrom()
    elif analysis == 'company': From = GetIRCSQLCompaniesFrom(identities_db)
    elif analysis == 'country': From = GetIRCSQLCountriesFrom(identities_db)
    elif analysis == 'domain': From = GetIRCSQLDomainsFrom(identities_db)

    return (From)



def GetIRCSQLReportWhere (type_analysis):
    #generic function to generate 'where' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    where = ""

    if (len(type_analysis) != 2): return where

    analysis = type_analysis[0]
    value = type_analysis[1]

    if analysis == 'repository': where = GetIRCSQLRepositoriesWhere(value)
    elif analysis == 'company': where = GetIRCSQLCompaniesWhere(value)
    elif analysis == 'country': where = GetIRCSQLCountriesWhere(value)
    elif analysis == 'domain': where = GetIRCSQLDomainsWhere(value)

    return (where)

# GLOBAL

def GetStaticDataIRC (period, startdate, enddate, i_db, type_analysis):

    # 1- Retrieving information
    sent = StaticNumSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders = StaticNumSendersIRC(period, startdate, enddate, i_db, type_analysis)
    repositories = StaticNumRepositoriesIRC(period, startdate	, enddate, i_db, type_analysis)

    # 2- Merging information
    static_data = dict(sent.items()+ senders.items()+ repositories.items())

    return (static_data)


def GetEvolDataIRC (period, startdate, enddate, i_db, type_analysis):

    # 1- Retrieving information
    sent = EvolSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders = EvolSendersIRC(period, startdate, enddate, i_db, type_analysis)
    repositories = EvolRepositoriesIRC(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    evol_data = dict(sent.items()+ senders.items()+ repositories.items())

    return (evol_data)


def StaticNumSentIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT count(message) as sent, \
              DATE_FORMAT (min(date), '%Y-%m-%d') as first_date, \
              DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    tables = " FROM irclog "
    filters = "WHERE date >=" + startdate + " and date < " + enddate
    filters += " AND type='COMMENT' "
    q = fields + tables + filters
    return(ExecuteQuery(q))

def StaticNumSendersIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT count(distinct(nick)) as senders"
    tables = " FROM irclog "
    filters = "WHERE date >=" + startdate + " and date < " + enddate
    filters += " AND type='COMMENT' "
    q = fields + tables + filters
    return(ExecuteQuery(q))

def StaticNumRepositoriesIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT COUNT(DISTINCT(channel_id)) AS repositories "
    tables = "FROM irclog "
    filters = "WHERE date >=" + startdate + " AND date < " + enddate
    filters += " AND type='COMMENT' "
    q = fields + tables + filters
    return(ExecuteQuery(q))

def GetSentIRC (period, startdate, enddate, identities_db, type_analysis, evolutionary):    
    fields = " count(distinct(message)) as sent "
    tables = " irclog " + GetSQLReportFrom(identities_db, type_analysis)
    filters = GetSQLReportWhere(type_analysis, "author")
    filters += " and type='COMMENT' "
    q = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))


def EvolSentIRC (period, startdate, enddate, identities_db, type_analysis):
    return(GetSentIRC(period, startdate, enddate, identities_db, type_analysis, True))


def GetSendersIRC (period, startdate, enddate, identities_db, type_analysis, evolutionary):    
    fields = " count(distinct(nick)) as senders "
    tables = " irclog " + GetSQLReportFrom(identities_db, type_analysis)
    filters = GetSQLReportWhere(type_analysis, "author")
    filters += " and type='COMMENT' "
    q = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))


def EvolSendersIRC (period, startdate, enddate, identities_db, type_analysis):
    return(GetSendersIRC(period, startdate, enddate, identities_db, type_analysis, True))


def GetRepositoriesIRC (period, startdate, enddate, identities_db, type_analysis, evolutionary):
    fields = " COUNT(DISTINCT(channel_id)) AS repositories "
    tables = " irclog " + GetSQLReportFrom(identities_db, type_analysis)
    filters = GetSQLReportWhere(type_analysis, "author")
    q = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))


def EvolRepositoriesIRC (period, startdate, enddate, identities_db, type_analysis):
    return(GetRepositoriesIRC(period, startdate, enddate, identities_db, type_analysis, True))


def GetTopSendersIRC (days, startdate, enddate, identities_db, bots):
    date_limit = ""
    filter_bots = ''
    for bot in bots:
        filter_bots += " nick<>'"+bot+"' and "
    if (days != 0 ):
        sql = "SELECT @maxdate:=max(date) from irclog limit 1"
        res = ExecuteQuery(sql)
        date_limit = " AND DATEDIFF(@maxdate, date)<"+str(days)
    q = "SELECT up.id as id, up.identifier as senders,"+\
        "       COUNT(irclog.id) as sent "+\
        " FROM irclog, people_upeople pup, "+identities_db+".upeople up "+\
        " WHERE "+ filter_bots +\
        "            irclog.type = 'COMMENT' and "+\
        "            irclog.nick = pup.people_id and "+\
        "            pup.upeople_id = up.id and "+\
        "            date >= "+ startdate+ " and "+\
        "            date  < "+ enddate+ " "+ date_limit +\
        "            GROUP BY senders "+\
        "            ORDER BY sent desc "+\
        "            LIMIT 10 "
    return(ExecuteQuery(q))

#
# Repositories (channels)
#

def GetTablesReposIRC () :
    return (GetTablesOwnUniqueIdsIRC(),",channels c")


def GetFiltersReposIRC () :
    filters = GetFiltersOwnUniqueIdsIRC() +" AND c.id = irclog.channel_id"
    return(filters)


def GetReposNameIRC ():
    q = "SELECT name, count(i.id) AS total "+\
        "  FROM irclog i, channels c "+\
        "  WHERE i.channel_id=c.id "+\
        "  GROUP BY name ORDER BY total DESC"
    return(ExecuteQuery(q)['name'])

def GetRepoEvolSentSendersIRC (repo, period, startdate, enddate):
    fields = 'COUNT(irclog.id) AS sent, COUNT(DISTINCT(pup.upeople_id)) AS senders'
    tables= GetTablesReposIRC()
    filters = GetFiltersReposIRC() + " AND c.name='"+repo+"'"
    filters += " AND irclog.type='COMMENT'"
    q = GetSQLPeriod(period,'date', fields, tables, filters, startdate, enddate)
    return(ExecuteQuery(q))

def GetRepoStaticSentSendersIRC (repo, startdate, enddate):
    fields = 'COUNT(irclog.id) AS sent,'+\
            'COUNT(DISTINCT(pup.upeople_id)) AS senders'
    tables = GetTablesReposIRC()
    filters = GetFiltersReposIRC()+" AND c.name='"+repo+"'"
    filters += " AND irclog.type='COMMENT'"
    q = GetSQLGlobal('date',fields, tables, filters, startdate, enddate)
    return(ExecuteQuery(q))

#########
# PEOPLE
#########
def GetListPeopleIRC (startdate, enddate) :
    fields = "DISTINCT(pup.upeople_id) as id, count(irclog.id) total"
    tables = GetTablesOwnUniqueIdsIRC()
    filters = GetFiltersOwnUniqueIdsIRC()
    filters += " AND irclog.type='COMMENT' "
    filters += " GROUP BY nick ORDER BY total desc"
    q = GetSQLGlobal('date',fields,tables, filters, startdate, enddate)
    return(ExecuteQuery(q))

def GetQueryPeopleIRC (developer_id, period, startdate, enddate, evol):
    fields = "COUNT(irclog.id) AS sent"
    tables = GetTablesOwnUniqueIdsIRC()
    filters = GetFiltersOwnUniqueIdsIRC() + " AND pup.upeople_id = " + str(developer_id)
    filters += " AND irclog.type='COMMENT'"

    if (evol) :
        q = GetSQLPeriod(period,'date', fields, tables, filters,
                startdate, enddate)
    else:
        fields = fields + \
                ",DATE_FORMAT (min(date),'%Y-%m-%d') as first_date,"+\
                " DATE_FORMAT (max(date),'%Y-%m-%d') as last_date"
        q = GetSQLGlobal('date', fields, tables, filters,
                startdate, enddate)
    return (q)

def GetEvolPeopleIRC (developer_id, period, startdate, enddate) :
    q = GetQueryPeopleIRC(developer_id, period, startdate, enddate, True)
    query = new("Query", sql = q)
    data = run(query)
    return (data)


def GetStaticPeopleIRC (developer_id, startdate, enddate) :
    q = GetQueryPeopleIRC(developer_id, period, startdate, enddate, False)
    query = new("Query", sql = q)
    data = run(query)
    return (data)

##############
# Microstudies
##############

def GetIRCDiffSentDays (period, init_date, days):
    # This function provides the percentage in activity between two periods.
    #
    # The netvalue indicates if this is an increment (positive value) or decrement (negative value)

    chardates = GetDates(init_date, days)
    lastmessages = StaticNumSentIRC(period, chardates[1], chardates[0])
    lastmessages = int(lastmessages['sent'])
    prevmessages = StaticNumSentIRC(period, chardates[2], chardates[1])
    prevmessages = int(prevmessages['sent'])

    data = {}
    data['diff_netsent_'+str(days)] = lastmessages - prevmessages
    data['percentage_sent_'+str(days)] = GetPercentageDiff(prevmessages, lastmessages)
    data['sent_'+str(days)] = lastmessages

    return data

def GetIRCDiffSendersDays (period, init_date, identities_db=None, days = None):
    # This function provides the percentage in activity between two periods:
    # Fixme: equal to GetDiffAuthorsDays

    chardates = GetDates(init_date, days)
    lastsenders = StaticNumSendersIRC(period, chardates[1], chardates[0], identities_db)
    lastsenders = int(lastsenders['senders'])
    prevsenders = StaticNumSendersIRC(period, chardates[2], chardates[1], identities_db)
    prevsenders = int(prevsenders['senders'])

    data = {}
    data['diff_netsenders_'+str(days)] = lastsenders - prevsenders
    data['percentage_senders_'+str(days)] = GetPercentageDiff(prevsenders, lastsenders)
    data['senders_'+str(days)] = lastsenders

    return data
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
## People.R
##
## Queries for source code review data analysis
##
## Authors:
##   Alvaro del Castillo <acs@bitergia.com>

from GrimoireSQL import ExecuteQuery

# _filter_submitter_id as a static global var to avoid SQL re-execute
def _init_filter_submitter_id():
    people_userid = 'l10n-bot'
    q = "SELECT id FROM people WHERE user_id = '%s'" % (people_userid)
    globals()['_filter_submitter_id'] = ExecuteQuery(q)['id']

# To be used for issues table
def GetIssuesFiltered():
    if ('_filter_submitter_id' not in globals()): _init_filter_submitter_id()
    filters = " submitted_by <> %s" % (globals()['_filter_submitter_id'])
    return filters

# To be used for changes table
def GetChangesFiltered():
    if ('_filter_submitter_id' not in globals()): _init_filter_submitter_id()
    filters = " changed_by <> %s" % (globals()['_filter_submitter_id'])
    return filters

########################################
# Quarter analysis: Companies and People
########################################

# No use of generic query because changes table is not used
# COMPANIES
def GetCompaniesQuartersSCR (year, quarter, identities_db, limit = 25):
    filters = GetIssuesFiltered()
    if (filters != ""): filters  += " AND "
    q = """
        SELECT COUNT(i.id) AS total, c.name, c.id, QUARTER(submitted_on) as quarter, YEAR(submitted_on) year
        FROM issues i, people p , people_upeople pup, %s.upeople_companies upc,%s.companies c
        WHERE %s i.submitted_by=p.id AND pup.people_id=p.id
            AND pup.upeople_id = upc.upeople_id AND upc.company_id = c.id
            AND status='merged'
            AND QUARTER(submitted_on) = %s AND YEAR(submitted_on) = %s
          GROUP BY year, quarter, c.id
          ORDER BY year, quarter, total DESC, c.name
          LIMIT %s
        """ % (identities_db, identities_db, filters,  quarter, year, limit)

    return (ExecuteQuery(q))


# PEOPLE
def GetPeopleQuartersSCR (year, quarter, identities_db, limit = 25, bots = []) :

    filter_bots = ''
    for bot in bots:
        filter_bots = filter_bots + " up.identifier<>'"+bot+"' AND "

    filters = GetIssuesFiltered()
    if (filters != ""): filters  = filter_bots + filters + " AND "
    else: filters = filter_bots

    q = """
        SELECT COUNT(i.id) AS total, p.name, pup.upeople_id as id,
            QUARTER(submitted_on) as quarter, YEAR(submitted_on) year
        FROM issues i, people p , people_upeople pup, %s.upeople up
        WHERE %s i.submitted_by=p.id AND pup.people_id=p.id AND pup.upeople_id = up.id
            AND status='merged'
            AND QUARTER(submitted_on) = %s AND YEAR(submitted_on) = %s
       GROUP BY year, quarter, pup.upeople_id
       ORDER BY year, quarter, total DESC, id
       LIMIT %s
       """ % (identities_db, filters, quarter, year, limit)

    return (ExecuteQuery(q))

################
# KPI queries
################

# People Code Contrib New and Gone KPI

def GetNewPeopleListSQL(period):
    filters = GetIssuesFiltered()
    if (filters != ""): filters  = " WHERE " + filters
    q_people = """
        SELECT submitted_by FROM (SELECT MIN(submitted_on) AS first, submitted_by
        FROM issues
        %s
        GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), first) <= %s) plist """ % (filters, period)
    return q_people

def GetGonePeopleListSQL(period):
    filters = GetIssuesFiltered()
    if (filters != ""): filters  = " WHERE " + filters
    q_people = """
        SELECT submitted_by FROM (SELECT MAX(submitted_on) AS last, submitted_by
        FROM issues
        %s
        GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), last)>%s) plist """ % (filters, period)
    return q_people

# Total submissions for people in period
def GetNewPeopleTotalListSQL(period, filters=""):

    issues_filters = GetIssuesFiltered()
    if (filters != ""):
        if issues_filters != "": filters += " AND " + issues_filters
    else: filters = issues_filters

    if (filters != ""): filters  = " WHERE " + filters
    q_total_period = """
        SELECT COUNT(id) as total, submitted_by, MIN(submitted_on) AS first
        FROM issues
        %s
        GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), first) <= %s
        ORDER BY total
        """ % (filters, period)
    return q_total_period

# Total submissions for people in period
def GetGonePeopleTotalListSQL(period, filters=""):

    issues_filters = GetIssuesFiltered()
    if (filters != ""):
        if issues_filters != "": filters += " AND " + issues_filters
    else: filters = issues_filters

    if (filters != ""): filters  = " WHERE " + filters
    q_total_period = """
        SELECT COUNT(id) as total, submitted_by, MAX(submitted_on) AS last
        FROM issues
        %s
        GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), last)>%s
        ORDER BY total
        """ % (filters, period)
    return q_total_period

# New/Gone people using period as analysis time frame
def GetNewGoneSubmittersSQL(period, fields = "", tables = "", filters = "",
                            order_by = "", gone = False):

    # Adapt filters for total: use issues table only
    filters_total = filters
    if "new_value='ABANDONED'" in filters:
        filters_total = "status='ABANDONED'"
    if "new_value='MERGED'" in filters:
        filters_total = "status='MERGED'"

    q_people = GetNewPeopleListSQL(period)
    q_total_period = GetNewPeopleTotalListSQL(period, filters_total)
    if (gone):
        q_people = GetGonePeopleListSQL(period)
        q_total_period = GetGonePeopleTotalListSQL(period, filters_total)


    if (tables != ""): tables +=  ","
    if (filters != ""): filters  += " AND "
    if (GetIssuesFiltered() != ""): filters += GetIssuesFiltered() + " AND "
    if (fields != ""): fields  += ","
    if (order_by != ""): order_by  += ","

    newgone = "<=";
    if (gone): newgone = ">";

    # Get the first submission for newcomers
    # SELECT %s url, submitted_by, name, email, submitted_on, status
    q= """
    SELECT %s url, submitted_by, name, email, submitted_on, status
    FROM %s people, issues_ext_gerrit, issues
    WHERE %s submitted_by = people.id AND DATEDIFF(NOW(), submitted_on) %s %s
          AND issues_ext_gerrit.issue_id = issues.id
          AND submitted_by IN (%s)
    ORDER BY %s submitted_on""" % \
        (fields, tables, filters, newgone, period, q_people, order_by)
    # Order so the group by take the first submission and add total
    # SELECT * FROM ( %s ) nc, (%s) total
    date_field = "first"
    if (gone): date_field = "last";
    q = """
    SELECT revtime, url,  nc.submitted_by, name, email, submitted_on, status, total, %s, upeople_id
    FROM ( %s ) nc, (%s) total, people_upeople pup
    WHERE total.submitted_by = nc.submitted_by AND pup.people_id =  nc.submitted_by
    GROUP BY nc.submitted_by ORDER BY nc.submitted_on DESC
    """ % (date_field, q, q_total_period)

    return q

def GetNewGoneSubmitters(gone = False):
    period = 90 # period of days to be analyzed
    if (gone): period = 180
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, NOW())/(24*3600) AS revtime"
    tables = ""
    filters = ""
    # filters = "status<>'MERGED' AND status<>'ABANDONED'"
    q = GetNewGoneSubmittersSQL(period, fields, tables, filters)
    if gone:
        q = GetNewGoneSubmittersSQL(period, fields, tables, filters, "", gone)
    return(ExecuteQuery(q))

def GetNewSubmitters():
    return GetNewGoneSubmitters()

def GetGoneSubmitters():
    return GetNewGoneSubmitters(True)

def GetNewGoneMergers(gone = False):
    period = 90 # period of days to be analyzed
    if (gone): period = 180
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = issues.id "
    filters += "AND field='status' AND new_value='MERGED'"
    order_by = "revtime DESC"
    q = GetNewGoneSubmittersSQL(period, fields, tables, filters, order_by)
    if (gone):
        q = GetNewGoneSubmittersSQL(period, fields, tables, filters, order_by, gone)
    return(ExecuteQuery(q))

def GetNewMergers():
    return GetNewGoneMergers()

def GetGoneMergers():
    return GetNewGoneMergers(True)

def GetNewGoneAbandoners(gone = False):
    period = 90 # period of days to be analyzed
    if (gone): period = 180
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = issues.id "
    filters += "AND field='status' AND new_value='ABANDONED'"
    order_by = "revtime DESC"
    q = GetNewGoneSubmittersSQL(period, fields, tables, filters, order_by)
    if (gone):
        q = GetNewGoneSubmittersSQL(period, fields, tables, filters, order_by, gone)
    return(ExecuteQuery(q))

def GetNewAbandoners():
    return GetNewGoneAbandoners()

def GetGoneAbandoners():
    return GetNewGoneAbandoners(True)

# New people activity patterns

def GetNewSubmittersActivity():
    period = 90 # days people activity recorded

    # Submissions total activity in period 
    q_total_period = GetNewPeopleTotalListSQL(period)

    q_people = GetNewPeopleListSQL(period)

    filters = GetIssuesFiltered()
    if (filters != ""): filters  += " AND "

    # Total submissions for new people in period
    q = """
        SELECT total, name, email, first, people_upeople.upeople_id
        FROM (%s) total_period, people, people_upeople
        WHERE %s submitted_by = people.id
          AND people.id = people_upeople.people_id
          AND submitted_by IN (%s)
        ORDER BY total DESC
        """ % (q_total_period, filters, q_people)
    return(ExecuteQuery(q))

# People leaving the project
def GetGoneSubmittersActivity():
    date_leaving = 90 # last contrib 3 months ago
    date_gone = 180 # last contrib 6 months ago

    q_all_people = """
        SELECT COUNT(issues.id) AS total, submitted_by,
               MAX(submitted_on) AS submitted_on, name, email
       FROM issues, people
       WHERE people.id = issues.submitted_by
       GROUP BY submitted_by ORDER BY total
       """

#    q_leaving = """
#        SELECT total, name, email, submitted_on, people_upeople.upeople_id  from
#          (%s) t, people_upeople
#        WHERE DATEDIFF(NOW(),submitted_on)>%s and DATEDIFF(NOW(),submitted_on)<=%s
#            AND people_upeople.people_id = submitted_by
#        ORDER BY submitted_on, total DESC
#        """ % (q_all_people,date_leaving,date_gone)

    filters = GetIssuesFiltered()
    if (filters != ""): filters  += " AND "

    q_gone  = """
        SELECT total, name, email, submitted_on, people_upeople.upeople_id from
          (%s) t, people_upeople
        WHERE %s DATEDIFF(NOW(),submitted_on)>%s
            AND people_upeople.people_id = submitted_by
        ORDER BY submitted_on, total DESC
        """ % (q_all_people, filters, date_gone)

    data = ExecuteQuery(q_gone)

    return data

def GetPeopleIntakeSQL(min, max):

    filters = GetIssuesFiltered()
    if (filters != ""): filters  = " WHERE " + filters

    q_people_num_submissions_evol = """
        SELECT COUNT(*) AS total, submitted_by,
            YEAR(submitted_on) as year, MONTH(submitted_on) as monthid
        FROM issues
        %s
        GROUP BY submitted_by, year, monthid
        HAVING total > %i AND total <= %i
        ORDER BY submitted_on DESC
        """ % (filters, min, max)


    q_people_num_evol = """
        SELECT COUNT(*) as people, year*12+monthid AS month
        FROM (%s) t
        GROUP BY year, monthid
        """ % (q_people_num_submissions_evol)

    return ExecuteQuery(q_people_num_evol)
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

########################################
# Quarter analysis: Companies and People
########################################

# No use of generic query because changes table is not used
# COMPANIES
def GetCompaniesQuartersSCR (year, quarter, identities_db, limit = 25):
    q = "  SELECT COUNT(i.id) AS total, c.name, c.id, QUARTER(submitted_on) as quarter, YEAR(submitted_on) year "+\
        "   FROM issues i, people p , people_upeople pup,  "+\
        "     "+identities_db+".upeople_companies upc,"+identities_db+".companies c "+\
        "   WHERE i.submitted_by=p.id AND pup.people_id=p.id  "+\
        "     AND pup.upeople_id = upc.upeople_id AND upc.company_id = c.id "+\
        "     AND status='merged' "+\
        "     AND QUARTER(submitted_on) = "+str(quarter)+" AND YEAR(submitted_on) = "+str(year)+" "+\
        "  GROUP BY year, quarter, c.id ORDER BY year, quarter, total DESC, c.name LIMIT "+str(limit)
    return (ExecuteQuery(q))


# PEOPLE
def GetPeopleQuartersSCR (year, quarter, identities_db, limit = 25, bots = []) :

    filter_bots = ''
    for bot in bots:
        filter_bots = filter_bots + " up.identifier<>'"+bot+"' and "


    q = "SELECT COUNT(i.id) AS total, p.name, pup.upeople_id as id, QUARTER(submitted_on) as quarter, YEAR(submitted_on) year "+\
           " FROM issues i, people p , people_upeople pup, "+ identities_db+".upeople up "+\
           " WHERE "+ filter_bots+ " "+\
           "  i.submitted_by=p.id AND pup.people_id=p.id AND pup.upeople_id = up.id "+\
           "  AND status='merged' "+\
           "  AND QUARTER(submitted_on) = "+str(quarter)+" AND YEAR(submitted_on) = "+str(year)+" "+\
           " GROUP BY year, quarter, pup.upeople_id ORDER BY year, quarter, total DESC, id LIMIT "+str(limit)
    return (ExecuteQuery(q))

################
# KPI queries
################

# People Code Contrib New and Gone KPI

def GetNewPeopleListSQL(period):
    q_new_people = """
        SELECT submitted_by FROM (SELECT MIN(submitted_on) AS first, submitted_by
        FROM issues GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), first)<%s) plist """ % (period)
    return q_new_people

# Total submissions for people in period
def GetNewPeopleTotalListSQL(period, filters=""):
    if (filters != ""): filters  = " WHERE " + filters
    q_total_period = """
        SELECT COUNT(id) as total, submitted_by, MIN(submitted_on) AS first
        FROM issues
        %s
        GROUP BY submitted_by
        HAVING DATEDIFF(NOW(), first)<%s
        ORDER BY total
        """ % (filters, period)
    return q_total_period

# New people in period with 1 submission
def GetNewSubmittersSQL(period, fields = "", tables = "", filters = "",
                        order_by = ""):

    # Adapt filters for total: use issues table only
    filters_total = filters
    if "new_value='ABANDONED'" in filters:
        filters_total = "status='ABANDONED'"
    if "new_value='MERGED'" in filters:
        filters_total = "status='MERGED'"

    q_new_people = GetNewPeopleListSQL(period)
    q_total_period = GetNewPeopleTotalListSQL(period, filters_total)

    if (tables != ""): tables +=  ","
    if (filters != ""): filters  += " AND "
    if (fields != ""): fields  += ","
    if (order_by != ""): order_by  += ","

    # Get the first submission for newcomers
    q= """
    SELECT %s url, submitted_by, name, email, submitted_on, status
    FROM %s people, issues_ext_gerrit, issues
    WHERE %s submitted_by = people.id AND DATEDIFF(NOW(), submitted_on)<%s
          AND issues_ext_gerrit.issue_id = issues.id
          AND submitted_by IN (%s)
    ORDER BY %s submitted_on""" % \
        (fields, tables, filters, period, q_new_people, order_by)
    # Order so the group by take the first submission and add total
    q = """
    SELECT * FROM ( %s ) nc, (%s) total 
    WHERE total.submitted_by = nc.submitted_by
    GROUP BY nc.submitted_by ORDER BY nc.submitted_on DESC
    """ % (q, q_total_period)
    return q

def GetNewSubmitters():
    period = 90 # period of days to be analyzed
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, NOW())/(24*3600) AS revtime_pending"
    tables = ""
    filters = "status<>'MERGED' AND status<>'ABANDONED'"
    q = GetNewSubmittersSQL(period, fields, tables, filters)
    return(ExecuteQuery(q))

def GetNewMergers():
    period = 90 # period of days to be analyzed
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = issues.id "
    filters += "AND field='status' AND new_value='MERGED'"
    order_by = "revtime DESC"
    q = GetNewSubmittersSQL(period, fields, tables, filters, order_by)
    return(ExecuteQuery(q))

def GetNewAbandoners():
    period = 90 # period of days to be analyzed
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = issues.id "
    filters += "AND field='status' AND new_value='ABANDONED'"
    order_by = "revtime DESC"
    q = GetNewSubmittersSQL(period, fields, tables, filters, order_by)
    return(ExecuteQuery(q))

# New people activity patterns

def GetNewSubmittersActivity():
    period = 90 # days
    min_submissions = 3 # to have enough data
    max_submissions = 20 # to detect new people

    # Submissions total activity in period 
    q_total_period = GetNewPeopleTotalListSQL(period)

    q_new_people = GetNewPeopleListSQL(period)

    # Total submissions for new people in period
    q = """
        SELECT total, name, email, first, people_upeople.upeople_id
        FROM (%s) total_period, people, people_upeople
        WHERE submitted_by = people.id AND total>%s AND total < %s
          AND people.id = people_upeople.people_id
          AND submitted_by IN (%s)
        ORDER BY total DESC
        """ % (q_total_period, min_submissions, max_submissions, q_new_people)
    return(ExecuteQuery(q))

# People leaving the project
def GetPeopleLeaving():
    date_leaving = 90 # last contrib 3 months ago
    date_gone = 180 # last contrib 6 months ago

    q_all_people = """
        SELECT COUNT(issues.id) AS total, submitted_by,
               MAX(submitted_on) AS submitted_on, name, email
       FROM issues, people
       WHERE people.id = issues.submitted_by
       GROUP BY submitted_by ORDER BY total
       """

    q_leaving = """
        SELECT name, submitted_by, email, submitted_on, total from
          (%s) t
        WHERE DATEDIFF(NOW(),submitted_on)>%s and DATEDIFF(NOW(),submitted_on)<=%s
        ORDER BY submitted_on, total DESC
        """ % (q_all_people,date_leaving,date_gone)

    q_gone  = """
        SELECT name, submitted_by, email, submitted_on, total from
          (%s) t
        WHERE DATEDIFF(NOW(),submitted_on)>%s
        ORDER BY submitted_on, total DESC
        """ % (q_all_people, date_gone)

    data = {"leaving":{},"mia":{}}
    data["gone"] = ExecuteQuery(q_gone)
    data["leaving"] = ExecuteQuery(q_leaving)

    return data

def GetPeopleIntakeSQL(min, max):
    q_people_num_submissions_evol = """
        SELECT COUNT(*) AS total, submitted_by,
            YEAR(submitted_on) as year, MONTH(submitted_on) as month
        FROM issues
        GROUP BY submitted_by, year, month
        HAVING total > %i AND total <= %i
        ORDER BY submitted_on DESC
        """ % (min, max)


    q_people_num_evol = """
        SELECT COUNT(*) as people, year*12+month AS monthid
        FROM (%s) t
        GROUP BY year, month
        """ % (q_people_num_submissions_evol)

    return ExecuteQuery(q_people_num_evol)

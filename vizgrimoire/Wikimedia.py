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
def GetNewSubmittersSQL(period, fields = "", tables = "", filters = "",
                        order_by = ""):

    if (tables != ""): tables +=  ","
    if (filters != ""): filters  += " AND "
    if (fields != ""): fields  += ","
    if (order_by != ""): order_by  += ","

    q= """
    SELECT %s url, submitted_by, name, email, submitted_on, status
    FROM %s
      (SELECT COUNT(id) AS total, id, submitted_by, submitted_on, status
       FROM issues GROUP BY submitted_by ORDER BY total) t,
      people, issues_ext_gerrit
    WHERE %s submitted_by = people.id AND total = 1 and DATEDIFF(now(), submitted_on)<%s
          AND issues_ext_gerrit.issue_id = t.id
    ORDER BY %s submitted_on DESC""" % (fields, tables, filters, period, order_by)

    return q

def GetNewSubmitters():
    period = 180 # period of days to be analyzed
    q = GetNewSubmittersSQL(period)
    return(ExecuteQuery(q))

def GetNewMergers():
    period = 180 # period of days to be analyzed
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = t.id "
    filters += "AND field='status' AND new_value='MERGED'"
    order_by = "revtime DESC"
    q = GetNewSubmittersSQL(period, fields, tables, filters, order_by)
    return(ExecuteQuery(q))

def GetNewAbandoners():
    period = 180 # period of days to be analyzed
    fields = "TIMESTAMPDIFF(SECOND, submitted_on, changed_on)/(24*3600) AS revtime"
    tables = "changes"
    filters = " changes.issue_id = t.id "
    filters += "AND field='status' AND new_value='ABANDONED'"
    order_by = "revtime DESC"
    q = GetNewSubmittersSQL(period, fields, tables, filters, order_by)
    return(ExecuteQuery(q))

# New people activity patterns

def GetNewSubmittersActivity():
    period = 180 # days

    # Submissions total activity in period 
    q_total_period = """
        SELECT  status, COUNT(id) as total, id, submitted_by, 
            MIN(submitted_on) AS first 
        FROM issues
        WHERE DATEDIFF(NOW(), submitted_on)<%s
        GROUP BY submitted_by ORDER BY total""" % (period)

    # First submission by people
    q_first_submission = """
        SELECT MIN(submitted_on) AS first, submitted_by 
        FROM issues group by submitted_by
        """
    # New people in period sending submissions
    q_new_people = """
        SELECT submitted_by FROM ( %s) t
        WHERE DATEDIFF(NOW(), first)<%s """ % (q_first_submission, period)

    # Total submissions for new people in period
    q = """
        SELECT total, name, email, first, people_upeople.upeople_id
        FROM (%s) total_period, people, people_upeople
        WHERE submitted_by = people.id and total < 20 and total>3
          AND people.id = people_upeople.people_id
          AND submitted_by IN (%s)
        ORDER BY total DESC
        """ % (q_total_period, q_new_people)
    return(ExecuteQuery(q))

# People leaving the project
def GetPeopleLeaving():
    date_leaving = 180 # last contrib 6 months ago
    date_gone = 365 # last contrib 1 year ago

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

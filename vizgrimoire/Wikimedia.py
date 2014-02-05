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
        "     AND QUARTER(submitted_on) = "+quarter+" AND YEAR(submitted_on) = "+year+" "+\
        "  GROUP BY year, quarter, c.id ORDER BY year, quarter, total DESC LIMIT "+limit
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
           "  AND QUARTER(submitted_on) = "+quarter+" AND YEAR(submitted_on) = "+year+" "+\
           " GROUP BY year, quarter, pup.upeople_id ORDER BY year, quarter, total DESC LIMIT "+limit
    return (ExecuteQuery(q))
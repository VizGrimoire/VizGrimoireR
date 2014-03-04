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

def GetPersonIdentifiers (upeople_id):
    q = """
        SELECT identity, type, cou.name as country, com.name as affiliation, up.identifier
        FROM upeople up, identities i,
            companies com, upeople_companies upcom,
            countries cou, upeople_countries upcou
        WHERE up.id ='%s' AND
            up.id = i.upeople_id AND
            upcom.upeople_id= up.id AND
            com.id = upcom.company_id AND
            upcou.upeople_id= up.id AND
            cou.id = upcou.country_id
        """ % (upeople_id)
    return (ExecuteQuery(q))

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
## This file is a part of the vizGrimoire package
##
##
## Authors:
##   Daniel Izquierdo-Cortazar <dizquierdo@bitergia.com>

import GrimoireUtils
import GrimoireSQL


def NewComersSCM(days, i_db):
    # Returns a list of newcomers in the last "days"
  
    query = """
            select t.identifier as name, 
                   t.first_date as first_date 
            from 
                (select u.identifier, 
                        min(s.date) as first_date 
                 from scmlog s, 
                      people_upeople pup, 
                      %s.upeople u 
                 where s.author_id = pup.people_id and 
                       pup.upeople_id = u.id 
                 group by u.id 
                 order by min(s.date) desc) t 
            where t.first_date > date_sub(now(), interval %s day)
            """ % (i_db, str(days))
    return(ExecuteQuery(query))         


def NewComersITS(days):
    # Returns a list of newcomers in the last "days"
    # This is done at the issue level, and not comments/changes level.
    query = """
            select t.identifier as name, 
                   t.first_date as first_date 
            from 
                 (select u.identifier as identifier,
                         min(i.submitted_on) as first_date
                  from issues i,
                       people_upeople pup,
                       %s.upeople u
                  where i.submitted_by = pup.people_id and
                        pup.upeople_id = u.id
                  group by u.id
                  order by min(i.submitted_on) desc) t 
            where t.first_date > date_sub(now(), interval %s day)
            """ % (i_db, str(days))
    return(ExecuteQuery(query))



def NewComersMLS(days, i_db):
    # Returns a list of newcomers in the last "days" 
    query = """
            select t.identifier as name, 
                   t.first_date as first_date 
            from 
                 (select u.identifier as identifier, 
                         min(m.first_date) as first_date 
                  from messages m, 
                       messages_people mp, 
                       people_upeople pup, 
                       %s.upeople u 
                  where m.message_ID = mp.message_id and 
                        mp.email_address = pup.people_id and 
                        pup.upeople_id = u.id 
                  group by u.identifier 
                  order by min(m.first_date) desc) t 
            where t.first_date > date_sub(now(), interval %s day)
            """ % (i_db, str(days))
    return(ExecuteQuery(query))

def NewComersSCR(days, i_db): 
    # Returns a list of newcomers in the last "days"
    # This is done at the review level, and not patch level.
    query = """
            select t.identifier as name, 
                   t.first_date as first_date 
            from 
                 (select u.identifier as identifier,
                         min(i.submitted_on) as first_date
                  from issues i,
                       people_upeople pup,
                       %s.upeople u
                  where i.submitted_by = pup.people_id and
                        pup.upeople_id = u.id
                  group by u.id
                  order by min(i.submitted_on) desc) t 
            where t.first_date > date_sub(now(), interval %s day)
            """ % (i_db, str(days))
    return(ExecuteQuery(query))




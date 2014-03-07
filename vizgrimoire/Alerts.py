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
from GrimoireSQL import ExecuteQuery


class Alert(object):

    def __init__ (self, output, destdir):
        # Type of output, typically panel, email, 
        # tweet and others to be defined.
        # Probably to define object for each of the cases and to be
        # provided by the customer
        self.output = output # type of output: panel, email
        self.destdir = destdir # directory of the output if needed

    def push(self, data):
        # Method to publish results of the alert
        # Depending on the selected self.output, this
        # method will publish results as an email,
        # JSON file, etc.
        if self.output == "panel":
            #GrimoireUtils.createJSON(data, self.destdir + "alert.json")
            print self.destdir + "alert.json"
        else:
            print "No identified output"
            pass

class NewComers(Alert):
    # Specific alert to obtain information about 
    # new people in the several repositories.

    def __init__ (self, output, destdir, days, identities_db, enddate):
        self.days = days # days of analysis
        self.i_db = identities_db # database of identities
        self.output = output
        self.destdir = destdir
        self.enddate = enddate
        
    def NewComersSCM(self):
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
            where t.first_date > date_sub('%s', interval %s day) and
                  t.first_date <= '%s'
            """ % (self.i_db, self.enddate, str(self.days), self.enddate)
        return(ExecuteQuery(query))         


    def NewComersITS(self):
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
            where t.first_date > date_sub('%s', interval %s day) and
                  t.first_date <= '%s'
            """ % (self.i_db, self.enddate, str(self.days), self.enddate)
        return(ExecuteQuery(query))



    def NewComersMLS(self):
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
            where t.first_date > date_sub('%s', interval %s day) and
                  t.first_date <= '%s'
            """ % (self.i_db, self.enddate, str(self.days), self.enddate)

        return(ExecuteQuery(query))

    def NewComersSCR(self): 
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
            where t.first_date > date_sub('%s', interval %s day) and
                  t.first_date <= '%s'
            """ % (self.i_db, self.enddate, str(self.days), self.enddate)
        return(ExecuteQuery(query))


class Turnover(Alert):
    # Turnover can be expressed as the number of people
    # leaving the community compared to the total workforce

    def __init__ (self, output, destdir, days, identities_db, enddate):
        self.days = days # After this number of days, a person becomes inactive
        self.i_db = identities_db # database of identities
        self.output = output
        self.destdir = destdir
        self.enddate = enddate # max date of analysis

    def turnoverSCM(self):
        # List of people that no committed anymore
        query = """
                select t.name, 
                       t.date 
                from 
                     (select u.identifier as name, 
                             max(s.date) as date 
                      from %s.upeople u, 
                           people_upeople pup, 
                           scmlog s 
                      where s.author_id = pup.people_id and 
                            pup.upeople_id = u.id group by u.id) t 
                where t.date < date_sub(%s, interval %s day) 
                order by t.date desc
                """ % (self.i_db, self.enddate, str(self.days))
        return(ExecuteQuery(query))

    def turnoverMLS(self):
        # List of people that did not send emails anymore
        query = """
                select t.name,
                       t.date
                from
                     (select u.identifier as name,
                             max(m.first_date) as date
                      from %s.upeople u,
                           people_upeople pup,
                           messages_people mp,
                           messages m
                      where m.message_ID = mp.message_id and 
                            mp.email_address = pup.people_id and
                            pup.upeople_id = u.id group by u.id) t 
                where t.date < date_sub('%s', interval %s day)                 
                      order by t.date desc
                """ % (self.i_db, self.enddate, str(self.days))
        return(ExecuteQuery(query))

    def turnoverITS(self):
        # List of people that did not open issues anymore
        query = """
                select t.name, 
                       t.date
                from
                     (select u.identifier as name, 
                             max(i.submitted_on) as date
                      from %s.upeople u,
                           people_upeople pup,
                           issues i
                      where i.submitted_by = pup.people_id and 
                            pup.upeople_id = u.id
                      group by u.id) t
                 where t.date < date_sub('%s', interval %s day)                 
                      order by t.date desc
                """ % (self.i_db, self.enddate, str(self.days))
        return(ExecuteQuery(query))


    def turnoverSCR(self): 
        # List of people that did not opened a review anymore
        return(self.turnoverITS())


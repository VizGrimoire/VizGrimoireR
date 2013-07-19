#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2012 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Authors :
#       Daniel Izquierdo-Cortazar <dizquierdo@bitergia.com>

#
# updateaffiliations.py
#
# Based on the structure of people_upeople, upeople, identities, upeople_companies
# and companies. This script parsers new developers coming into the community.
# Those are based on domain analysis using a file similar to gitdm "domain-map".
# The match between developer and affiliation is is needed to insert those new affiliations

import MySQLdb
import sys
import re
import datetime



def connect(database):
   user = 'root'
   password = ''
   host = 'localhost'
   try:
      db =  MySQLdb.connect(host,user,password,database)
      return db.cursor()
   except:
      print("Database connection error")


def execute_query(connector, query):
   results = int (connector.execute(query))
   cont = 0
   if results > 0:
      result1 = connector.fetchall()
      return result1
   else:
      return []

def get_domains(file_path):
   # list of domains per company based on gitdm format

   fd = open(file_path, 'r')
   domains_companies = fd.readlines()
   
   domains = []
   companies = []
   for domain_company in domains_companies[1:]:
      domains.append(domain_company.split(' ')[0])
      companies.append(domain_company.rsplit(' ', 1)[1])

   return domains, companies


def get_new_people(connector, domain):
   # list of people that appears in scmlog (CVSANALY db)
   # with no affiliation in upeople_companies
   # no affiliation = no entry for such developer in upeople_companies table

   query = " select i.upeople_id " +\
           " from identities i, " +\
           "      people_upeople pup " +\
           " where identity like '%@"+domain+"%' " +\
           "       and pup.upeople_id = i.upeople_id " +\
           "       and i.upeople_id not in (select upeople_id " +\
                                            "from upeople_companies);"
   upeople_id = execute_query(connector, query)

   return upeople_id


def get_info_developer(connector, upeople_id):
   # prints all associated info for a given upeople_id

   # upeople table information
   query = "select identifier from upeople where id= "+ str(upeople_id)
   print query
   identifier = execute_query(connector, query)[0]
   print "UPEOPLE TABLE: "
   print "    upeople_id: " + str(upeople_id)
   print "    identifier: " + str(identifier[0])

   # people table information
   query = "select p.name, " +\
           "       p.email " +\
           " from people p, " +\
           "      people_upeople pup " +\
           " where pup.upeople_id = " + str(upeople_id) +\
           " and pup.people_id = p.id"
   dev_info = execute_query(connector, query)
   print "PEOPLE TABLE: "
   print "    name: " + str(dev_info[0][0])
   print "    email: " + str(dev_info[0][1])

   # identities table information
   query = " select identity " +\
           " from identities where " +\
           " upeople_id = " + str(upeople_id)
   identities = execute_query(connector, query)
   print "IDENTITIES TABLE: "
   for identity in identities:
      print "    identity: " + str(identity[0])
   return

def insert_in_company(connector, developer, company):

   # get company_id
   company = company.replace('\n', '')
   query = "select id from companies where name like '%"+company+"%'"
   company_id = execute_query(connector, query)
   company_id = int(company_id[0][0])

   #get min date of first commit for that developer
   query = " select min(s.date) " +\
           " from scmlog s, people p, people_upeople pup " + \
           " where pup.upeople_id = " + str(developer)  +\
           " and pup.people_id = p.id " +\
           " and p.id = s.author_id "
   min_date = ""
   min_date = execute_query(connector, query)
   min_date = min_date[0][0]
   # insert data into database
   query = " insert into upeople_companies " + \
           " (upeople_id, company_id, init, end) " +\
           " values("+str(developer)+", "+str(company_id)+", "
   if min_date <> "":
      query = query + "'" + str(min_date) + "', '2100-01-01')"
   else:
      query = query + "'1900-01-01', '2100-01-01')"
   execute_query(connector, query)
   return      


def main(database, domain_map):

   connector = connect(database)
   domains, companies = get_domains(domain_map)

   for domain in domains:
      print "Current domain: " + domain
      people = get_new_people(connector, domain)
      for developer in people:
         dev_id = int(developer[0])
         get_info_developer(connector, dev_id)
         print "Expected company: " + companies[domains.index(domain)]
         print "Insert developer in company?"
         answer = ""
         while answer <> 'y' and answer <>'n':
            answer = raw_input("Insert developer in company? (y/n): ")
            if answer == 'y':
               insert_in_company(connector, dev_id, companies[domains.index(domain)])
               print "Developer inserted..."
            if answer == 'n':
               print "Developer not inserted..."


if __name__ == "__main__":main(sys.argv[1], sys.argv[2])



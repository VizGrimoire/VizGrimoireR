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
# domain_employer.py
#
# This scripts is based on the outcomes of unifypeople.py.
# This will provide two tables: companies and upeople_companies
# And this is expecting a file with specific pattern: 'domain' 'employer'
# (similar to git-dm format to map domains to employers)
# if the domain is not found, that developer is assigned to unknown
# employer


import MySQLdb
import sys
import re

def create_tables(db, connector):
   query = "DROP TABLE IF EXISTS companies"
   connector.execute(query)
   query = "DROP TABLE IF EXISTS upeople_companies"
   connector.execute(query)

   query = "CREATE TABLE companies (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "name varchar(255) NOT NULL," + \
           "PRIMARY KEY (id)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8"

   connector.execute(query)

   query = "CREATE TABLE upeople_companies (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "upeople_id int(11) NOT NULL," + \
           "company_id int(11) NOT NULL," + \
           "init datetime," + \
           "end datetime," + \
           "PRIMARY KEY (id)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8"
   connector.execute(query)

   db.commit()
   return

def connect(database):
   user = ''
   password = ''
   host = ''
   try:
      db =  MySQLdb.connect(host,user,password,database)
      return db, db.cursor()
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

def parse_domain_companies(dc_file):
   
   fd = open(dc_file, 'r')
   dcs = fd.readlines()
   domain_companies = {}
   
   for dc in dcs:
      #dc: one item with a domain and its company
      domain, company = dc.split(' ', 1)
      domain_companies[domain] = company.replace("\n", "")

   return domain_companies

def main(database, dc_file):
   # database: resultant database
   # dc_file: domain companies file

   #charging info from the file into a dictionary
   domain_companies = parse_domain_companies(dc_file)
   
   #creating list of companies and adding an extra unknown employer
   
   companies = domain_companies.values()
   companies.insert(0, "unknown")
   companies = list(set(companies))

   domains = domain_companies.keys()
   domains = list(set(domains))
    
   pe_com = {}

   db, connector = connect(database)

   create_tables(db, connector)

   query = "select upeople_id, identity from identities where type='email';"
   people = execute_query(connector, query)

   rexp = "(.*@)(.*)"

   for person in people:    
      author_id = int(person[0])
      email = str(person[1])
      if len(email) == 0:
         if not pe_com.has_key(author_id):
            #if the author does not exist, then this is included, 
            # else: it does not make sense: this is already assigned to a 
            #       company or this is again unknown.
            pe_com[author_id] = []
            pe_com[author_id].append(companies.index("unknown") + 1)
      if re.match(rexp, email):
         m = re.match(rexp, email)
         domain = str(m.groups()[1])
         if domain not in domains:
            if not pe_com.has_key(author_id):
            #if the author does not exist, then this is included, 
            # else: it does not make sense: this is already assigned to a
            #       company or this is again unknown.
               pe_com[author_id] = []
               pe_com[author_id].append(companies.index("unknown") + 1)
         else:
            company = domain_companies[domain]
            if not pe_com.has_key(author_id):
               pe_com[author_id] = []
               pe_com[author_id].append(companies.index(company) + 1) #+1 in orddr to avoid the insertion of 0 in the database
            else:
               pe_com[author_id].append(companies.index(company) + 1)
      else:
         if not pe_com.has_key(author_id):
            #if the author does not exist, then this is included, 
            # else: it does not make sense: this is already assigned to a
            #       company or this is again unknown.
            pd_com[author_id] = []
            pe_com[author_id].append(companies.index("unknown") + 1)
   
   #inserting data in upeople_companies table
   for item in pe_com.iteritems():
      author_id = int(item[0])
      companies_in_author = item[1]
      for company in companies_in_author:
         if len(companies_in_author) > 1 and company == companies.index("unknown") + 1:
            #ignore this company. There are others, so unknown should not be inserted
            continue
         company_id = int(company)
         query = "INSERT INTO upeople_companies(upeople_id, company_id, init, end) " + \
                 "VALUES(" + str(author_id) + "," + \
                             str(company_id) + "," + \
                             "'1900-01-01', '2100-01-01' );"
         connector.execute(query)
   #inserting companies in companies table      
   for company in companies:
      query = "INSERT INTO companies(name) " +\
              "VALUES('" + str(company) + "');"
      connector.execute(query)
      


if __name__ == "__main__":main(sys.argv[1], sys.argv[2])



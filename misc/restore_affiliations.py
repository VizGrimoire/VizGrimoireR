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

# There are cases where the whole analysis process should be re-started.
# However once affiliations are tunned, it's a hard work to re-start this
# specific task.
# This script aims at re-filling the upeople_companies table when a CVSAnalY
# database is restarted. As input, this script needs a file with the following
# structure: identity;company;init_date;end_date
# The whole process should be as follows:
# 1- Obtain previous mentioned file with the following query:
# select distinct u.identifier, c.name, upc.init, upc.end from people_upeople pup, upeople u, upeople_companies upc, companies c where u.id=upc.upeople_id and upc.company_id = c.id and u.id=pup.upeople_id order by u.identifier into outfile '/tmp/affiliations.csv' fields terminated by ';' lines terminated by '\n';
# 2- Re-run cvsanaly 
# 3- Re-run unifypeople.py script, so identities, upeople and people_upeople tables are created and populated
# 4- Copy old companies table as follows: create table companies as select * from <old_database>.companies
# 5- Run this script: $ python restore_affiliations.py <database> <file with affs>

import MySQLdb
import sys
import re

def connect(database):
   # Connect to database
   user = 'root'
   password = ''
   host = 'localhost'
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


def create_upeople_companies_table(connector):
   # Creates the upeople_companies table

   query = "DROP TABLE IF EXISTS upeople_companies"
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
   return

def insert_company(connector, company):
   # if company is not found, this is inserted, 
   # in other case the company_id is returned
   company_id = -1

   query = "select id from companies where name = '"+company+"'"
   results = execute_query(connector, query)
   if len(results) == 0:
      # new company detected
      query = "insert into companies(name) values('"+company+"')"
      execute_query(connector, query)
      
      query = "select id from companies where name='"+company.title()+"'"
      results = execute_query(connector, query)
      company_id = int(results[0][0])
   else:
      company_id = int(results[0][0])
   return company_id


def get_upeople_id(connector, dev):
   # returns the unique people_id identifier (upeople_id)
   # for the new identity found.

   upeople_id = -1

   query = "select distinct(upeople_id) from identities where identity like '%"+dev+"%';"
   results = execute_query(connector, query)
   if len(results) > 0:
      upeople_id = int(results[0][0])
   return upeople_id

def insert_upeople_companies(connector, upeople_id, company_id, init, end):
   # if the process works, a new entry is found in the upeople_companies table 

   query = "insert into upeople_companies(upeople_id, company_id, init, end) " + \
                     "values("+ str(upeople_id) + ", " + \
                     str(company_id) + ", " + \
                     "'" + init + "', " + \
                     "'" + end + "');"

   execute_query(connector, query)

def main(database, affs_file):
   # database: resultant database
   # affs_file:  affiliations file
   # This script recreates the upeople_people and companies table
   # from an installation from scratch of CVSAnalY, but with already
   # obtained information about affiliations
   # Tipically, this script is used if the CVSAnalY database is 
   # inconsistent and the whole process needs to be restarted.

   db, connector = connect(database)
   create_upeople_companies_table(connector)

   fd = open(affs_file, 'r')
   people_data = fd.readlines()
   fd.close()

   cont = 0
   for developer in people_data:
      data = developer.split(";")
      originaldev = data[0]
      dev = originaldev.replace("'", "")
      company = data[1]
      init = data[2]
      end = data[3]
      
      upeople_id = get_upeople_id(connector, dev) 
      if upeople_id == -1:
         print "Error: " + originaldev
         continue
      company_id = insert_company(connector, company)
      insert_upeople_companies(connector, upeople_id, company_id, init, end)
      cont = cont + 1

   db.commit()
   print "There were " + str(len(people_data)) + " rows "
   print "    " + str(cont) + " correctly inserted "
   return 



if __name__ == "__main__":main(sys.argv[1], sys.argv[2])



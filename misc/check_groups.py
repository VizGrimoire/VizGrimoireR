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
# check_groups.py
#
# This scripts is based on the outcomes of unifypeople.py and
# (domain_employer.py or domains_analysis.py).
# This will insert in upeople_companies and companies the rest of 
# companies specified by the name of the files found in the "groups"
# directory. Those developers should be found in the git as developer
# (thus, they should be in the identities table), or 
# they will not be inserted.


import MySQLdb
import sys
import os

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

def insert_in_company(person, company_name, connector, db):

   #specific names different in the database
   if company_name == "att":
      company_name = "AT&T"
   if company_name == "unimelb":
      company_name = "University of Melbourne"
   if company_name == "piston":
      company_name = "Piston Cloud"
   if company_name == "redhat":
      company_name = "Red Hat"

   #name of the company is not case sensitive in mysql
   query = "select id from companies where name like '"+ company_name  +"';"
   results = execute_query(connector, query)

   if len(results) == 0:
      #company not found
      #let's insert new company
      print "Company " + company_name + " not found."
      company_name = company_name.title()
      query = "insert into companies(name) values('" + company_name + "');"
      execute_query(connector, query)
      query = "select id from companies where name like '"+ company_name  +"';"
      results = execute_query(connector, query)
      db.commit()
      print "Company " + company_name + " already inserted"


   company_id = int(results[0][0])
   person = person.replace("\n", "")
   query = "select upeople_id from identities where identity ='"+ person  +"';"
   results = execute_query(connector, query)
   if len(results) > 0:
      upeople_id = int(results[0][0])
      query = "insert into upeople_companies(upeople_id, company_id)" + \
           " values(" + str(upeople_id) + ", " + str(company_id) + ");"

      print query
      execute_query(connector, query)
   else:
      print "Person " + person + " not found"
      #Person not found, this is ignored.
      #left as further work the insertion or not (to be discussed)
      pass
      
   db.commit()


def main(database, directory):
   # database: resultant database
   # directory: where the companies groups

   db, connector = connect(database)

   files = os.listdir(directory)

   for file_name in files:
      final_path = os.path.join(directory, file_name)
      fd = open(final_path, 'r')
      people = fd.readlines()
      for person in people:
         insert_in_company(person, file_name, connector, db)




if __name__ == "__main__":main(sys.argv[1], sys.argv[2])



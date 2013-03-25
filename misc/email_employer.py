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
# email_employer.py
#
# This script is based on the outcomes of unifypeople.py, domain_employer.py
# or domains_analysis.py and this needs a file with the pattern:
# 'email address' 'company' 'final date'
# This script basically updates information in upeople_companies.
#
# A basic assumption of this script is that this information does not
# previously exists. This means that information already there will be
# duplicated


import MySQLdb
import sys
import re

def connect(database):
   user = 'xxx'
   password = 'xxx'
   host = 'xxx'
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


def retrieve_companies_info(connector):
   # a dictionary with company company_id is returned

   companies = {}

   query = "select name, id from companies"
   results = execute_query(connector, query)
   
   for result in results:
      companies[result[0].lower()] = int(result[1])

   return companies


def parse_people_data(people_data):
   # pattern expected: "email" "company" < "date"

   people_companies = {}

   for person_data in people_data:
      final_date = ""
      aux = person_data.split(' ', 1)
      email = aux[0] 
      company_data = aux[1].split(' < ')
      company = company_data[0].replace('\n','')
      if len(company_data) > 1:
         #there's a date for such employer
         final_date = company_data[1].replace('\n','')

      if not people_companies.has_key(email):
         people_companies[email] = []
      people_companies[email].append((company,final_date))

   return people_companies


def insert_dates(people_companies):
   
   people_companies_dates = {}

   for person_companies in people_companies.iteritems():
      email = person_companies[0]
      extra_data = person_companies[1] #company final_date

      if len(extra_data) > 1:
         extra_data.reverse()
         cont = 0
         people_companies_dates[email] = []
         init_date = '1900-01-01'
         data = extra_data[cont]
         while len(data[1]) > 0: #so the final_date must exist
            values = (data[0], init_date, data[1]) #company, init_date, end_date
            people_companies_dates[email].append(values)
            init_date = data[1]
            cont = cont + 1
            data = extra_data[cont]
         data = extra_data[cont]
         values = (data[0], init_date, '2100-01-01')
         people_companies_dates[email].append(values)
 
      else:
         people_companies_dates[email] = [] 
         people_companies_dates[email].append((extra_data[0][0], '1900-01-01', '2100-01-01'))

   return people_companies_dates

def insert_company(connector, company):
   company_id = -1

   query = "select * from companies where name = '"+company+"'"
   results = execute_query(connector, query)
   if len(results) == 0:
      # new company detected
      query = "insert into companies(name) values('"+company+"')"
      execute_query(connector, query)
      
      query = "select id from companies where name='"+company.title()+"'"
      results = execute_query(connector, query)
      company_id = int(results[0][0])

   return company_id

def main(database, ee_file):
   # database: resultant database
   # ee_file:  email employer file

   db, connector = connect(database)

   fd = open(ee_file, 'r')
   people_data = fd.readlines()
   fd.close()

   companies = retrieve_companies_info(connector)

   people_companies = parse_people_data(people_data)

   people_companies_dates = insert_dates(people_companies)



   
   for person_companies in people_companies_dates.iteritems():
      email = person_companies[0]
      for extra_data in person_companies[1]:
         company = extra_data[0].lower()
         init_date = extra_data[1]
         end_date = extra_data[2]
         #Inserting new companies (if this is the case) in companies table
         company_id = insert_company(connector, company)
         if company_id <> -1:
            print "New company: " + company + ", id: " + str(company_id)
            companies[company] = company_id

         # Retrieving data from email
         query = "select upeople_id from identities where identity = '"+ email +"' limit 1;"
         results = execute_query(connector, query)
         if not len(results) > 0:
            continue # simply ignored
         upeople_id = int(results[0][0])
      
         # Inserting new companies into table
         query = "insert into upeople_companies(upeople_id, company_id, init, end) " + \
                  "values("+ str(upeople_id) + ", " + \
                  str(companies[company.lower()]) + ", " + \
                  "'" + init_date + "', " + \
                  "'" + end_date + "');"
         execute_query(connector, query)


   db.commit()
   return 



if __name__ == "__main__":main(sys.argv[1], sys.argv[2])



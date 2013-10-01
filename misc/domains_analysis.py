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
# domains_analysis.py
#
# This scripts is based on the outcomes of unifypeople.py.
# This will provide two tables: companies and upeople_companies


import MySQLdb
import sys
import re
from optparse import OptionGroup, OptionParser

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

   try:
       query = "CREATE INDEX companies_names ON companies (name)"
       connector.execute(query)
   except Exception:
       print "Index companies.names  already created"

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

def connect(cfg):
   user = cfg.db_user
   password = cfg.db_password
   host = cfg.db_hostname
   db = cfg.db_database

   try:
      db = MySQLdb.connect(user = user, passwd = password, db = db)      
      return db, db.cursor()
   except:
      print("Database connection error")
      raise


def execute_query(connector, query):
   results = int (connector.execute(query))
   cont = 0
   if results > 0:
      result1 = connector.fetchall()
      return result1
   else:
      return []
  
def getOptions():     
    parser = OptionParser(usage='Usage: %prog [options]', 
                          description='Companies detection using email domains',
                          version='0.1')
    
    parser.add_option('-d', '--db-database', dest='db_database',
                     help='Output database name', default=None)
    parser.add_option('-u','--db-user', dest='db_user',
                     help='Database user name', default='root')
    parser.add_option('-p', '--db-password', dest='db_password',
                     help='Database user password', default='')
    parser.add_option('--db-hostname', dest='db_hostname',
                     help='Name of the host where database server is running',
                     default='localhost')
    parser.add_option('--db-port', dest='db_port',
                     help='Port of the host where database server is running',
                     default='3306')
    
    (ops, args) = parser.parse_args()
    
    return ops


def main(db):

   companies = ["unknown"]
   pe_com = {}
   
   cfg = getOptions()
   
   db, connector = connect(cfg)

   create_tables(db, connector)

   query = "select upeople_id, identity from identities where type='email';"
   people = execute_query(connector, query)

   rexp = "(.*@)(.*)"

   for person in people:    
      author_id = int(person[0])
      email = str(person[1])
      #email = str(person[2])
      if len(email) == 0:
         pe_com[author_id] = 1 #unknown company
      if re.match(rexp, email):
         m = re.match(rexp, email)
         company = str(m.groups()[1].split('.')[0])
         if company not in companies:
            companies.append(company)
         pe_com[author_id] = (companies.index(company) + 1) #+1 in order to avoid the insertion of 0 in the database
      else:
         pe_com[author_id] = 1
   
   #inserting data in upeople_companies table
   for item in pe_com.iteritems():
      author_id = int(item[0])
      company_id = int(item[1])
      query = "INSERT INTO upeople_companies(upeople_id, company_id, init, end) " + \
              "VALUES(" + str(author_id) + "," + \
                          str(company_id) + "," + \
                          "'1900-01-01', '2100-01-01' );"
      connector.execute(query)

   #inserting companies in companies table      
   for company in companies:
      query = "INSERT INTO companies(name) " +\
              "VALUES('" + company + "');"
      connector.execute(query)
      
if __name__ == "__main__":main(sys.argv[1])
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
#   query = "DROP TABLE IF EXISTS companies"
#   connector.execute(query)
#   query = "DROP TABLE IF EXISTS upeople_companies"
#   connector.execute(query)

   query = "CREATE TABLE IF NOT EXISTS companies (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "name varchar(255) NOT NULL," + \
           "PRIMARY KEY (id)," + \
           "UNIQUE KEY (name)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8 "

   connector.execute(query)

   try:
       query = "CREATE INDEX companies_names ON companies (name)"
       connector.execute(query)
   except Exception:
       print "Index companies.names  already created"

   query = "CREATE TABLE IF NOT EXISTS upeople_companies (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "upeople_id int(11) NOT NULL," + \
           "company_id int(11) NOT NULL," + \
           "init datetime," + \
           "end datetime," + \
           "PRIMARY KEY (id)," + \
           "UNIQUE KEY (upeople_id, company_id, init)" + \
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

def insert_company(connector, name):
    q = "INSERT INTO companies (name) VALUES ('"+name+"')";
    execute_query(connector, q)

def get_company_id(connector, name):
    company_id = None
    q = "SELECT id FROM companies WHERE name ='"+name+"'"
    res = execute_query(connector, q)
    if len(res) == 0:
        insert_company(connector,name)
        company_id = get_company_id(connector, name)
    else: company_id = res[0][0]
    return company_id

def insert_upeople_company(connector, upeople_id, company_id):
    q = "INSERT INTO upeople_companies(upeople_id, company_id, init, end) " + \
            "VALUES(" + str(upeople_id) + "," + \
            str(company_id) + "," + \
            "'1900-01-01', '2100-01-01' );"
    try:
        execute_query(connector, q)
    except:
        print "Already inserted: " +str(upeople_id)+ " in company "+ str(company_id) + " in 1900-01-01"


def main(db):
   cfg = getOptions()   
   db, connector = connect(cfg)
   create_tables(db, connector)
   query = "select upeople_id, identity from identities where type='email';"
   people = execute_query(connector, query)   
   rexp = "(.*@)(.*)"
   
   for person in people:    
      upeople_id = int(person[0])
      email = str(person[1])
      if len(email) == 0:
         company_id = get_company_id(connector, 'Unknown')
      if re.match(rexp, email):
         m = re.match(rexp, email)
         company = str(m.groups()[1].split('.')[0])
         company_id = get_company_id(connector, company)
      insert_upeople_company(connector, upeople_id, company_id)
      
if __name__ == "__main__":main(sys.argv[1])
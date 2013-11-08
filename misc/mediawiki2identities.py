#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2013 Bitergia
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
#       Alvaro del Castillo <acs@bitergia.com>

#
# mediawiki2identities.py
#
# This script is based on the outcomes of unifypeople.py used in the CVSAnalY
# database. This checks information about name and email from the email accounts
# found in the people table (outcomes of the MLStats tool). If this is found,
# then the table people_upeople is populated with the upeople_id found in identities.
# If not, a new entry in identities table is generated and its correspondant link
# to the people_upeople table.


import MySQLdb
import sys
import re
from optparse import OptionGroup, OptionParser

from optparse import OptionGroup, OptionParser

def getOptions():     
    parser = OptionParser(usage='Usage: %prog [options]', 
                          description='MediaWiki unique identities',
                          version='0.1')    
    parser.add_option('--db-database-mediawiki', dest='db_database_mediawiki',
                     help='IRC database name', default=None)
    parser.add_option('--db-database-ids', dest='db_database_ids',
                     help='Identities database name', default=None)
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

def connect(db, cfg):
   user = cfg.db_user
   password = cfg.db_password
   host = cfg.db_hostname

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

def create_tables(db, connector):
   connector.execute("DROP TABLE IF EXISTS people_upeople")
   connector.execute("""CREATE TABLE people_upeople (
                               people_id varchar(256) NOT NULL,
                               upeople_id int(11) NOT NULL,
                               PRIMARY KEY (people_id)
                  ) ENGINE=MyISAM DEFAULT CHARSET=utf8""")
   connector.execute("ALTER TABLE people_upeople DISABLE KEYS")
   db.commit()

   return

def escape_string (message):
    if "\\" in message:
        message = message.replace("\\", "\\\\")
    if "'" in message:
        message = message.replace("'", "\\'")
    return message

def main():
   cfg = getOptions()

   db_mediawiki, connector_mediawiki = connect(cfg.db_database_mediawiki, cfg)
   db_ids, connector_ids = connect(cfg.db_database_ids, cfg)

   create_tables(db_mediawiki, connector_mediawiki)

   query = "select DISTINCT(user) from wiki_pages_revs"
   results = execute_query(connector_mediawiki, query)
   total = len(results)
   newids = 0
   reusedids = 0
   done = 0
   import sys
   print ("Total identities to analyze: " + str(total))
   for result in results:
      done += 1
      if (done % 100 == 0): print (str(done)+" ("+str(total-done)+" pend)")
      name = result[0]
      if name == '': continue
      name = escape_string (name)
      query = "select upeople_id from identities where identity='" + name  + "';"
      results_ids = execute_query(connector_ids, query)
      if len(results_ids) > 0:
         reusedids = reusedids+1
         # print ("Reusing "+name)
         # there exist such identity
         upeople_id = int(results_ids[0][0])
         query = "insert into people_upeople(people_id, upeople_id) " +\
                 "values('"+name+"', "+str(upeople_id)+");"
         execute_query(connector_mediawiki, query)
      else:
         newids = newids+1
         # print ("New identity "+name)

         #Insert in people_upeople, identities and upeople (new identitiy)
         uidentifier = name
 
         # Max (upeople_)id from upeople table
         query = "select max(id) from upeople;"
         results = execute_query(connector_ids, query)
         upeople_id = int(results[0][0]) + 1
         
         # query = "insert into upeople(id) values("+ str(upeople_id) +");"
         query = "insert into upeople (id, identifier) values(" + str(upeople_id) + ",'"+uidentifier+"');"
         execute_query(connector_ids, query)
         
         query = "insert into identities (upeople_id, identity, type)" +\
                 "values(" + str(upeople_id) + ", '"+name+"', 'nick');"
         execute_query(connector_ids, query)
 
         query = "insert into people_upeople(people_id, upeople_id) " +\
                 "values('"+name+"', "+str(upeople_id)+");"
         # print query
         execute_query(connector_mediawiki, query)

   db_ids.commit()
   print ("Total analyzed: " + str(total))
   print ("New identities: " + str(newids))
   print ("Reused identities: " + str(reusedids))
   return

if __name__ == "__main__":main()
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
#       Alvaro del Castillo <acs@bitergia.com>

#
# its2identities.py
#
# This script is based on the outcomes of unifypeople.py used in the CVSAnalY
# database. This checks information about name and email from the email accounts
# found in the people table (outcomes of the Bicho tool). If this is found,
# then the table people_upeople is populated with the upeople_id found in identities.
# If not, a new entry in identities table is generated and its correspondant link
# to the people_upeople table.


import MySQLdb
import sys
import re
from optparse import OptionGroup, OptionParser

def getOptions():     
    parser = OptionParser(usage='Usage: %prog [options]',
                          description='Companies detection using email domains',
                          version='0.1')
    
    parser.add_option('--db-database-its', dest='db_database_its',
                     help='ITS database name', default=None)
    parser.add_option('--db-database-ids', dest='db_database_ids',
                     help='Identities database name', default=None)
    parser.add_option('-u', '--db-user', dest='db_user',
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
      db = MySQLdb.connect(user=user, passwd=password, db=db)      
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
                               people_id int(11) NOT NULL,
                               upeople_id int(11) NOT NULL,
                               PRIMARY KEY (people_id)
                  ) ENGINE=MyISAM DEFAULT CHARSET=utf8""")
   connector.execute("ALTER TABLE people_upeople DISABLE KEYS")
   db.commit()

   return

def insert_identity(connector_ids, connector_its, people_id, 
                    name, email, user_id):
    # Insert in people_upeople, identities and upeople (new identitiy)
 
    # Max (upeople_)id from upeople table
    query = "select max(id) from upeople;"
    results = execute_query(connector_ids, query)
    upeople_id = int(results[0][0]) + 1
 
    uidentifier = upeople_id
    if email and email != 'None': 
        uidentifier = email 
    elif name and name != 'None':
        uidentifier = name 
    elif user_id and user_id != 'None':
        uidentifier = user_id 
    query = "insert into upeople(id, identifier) values(" + str(upeople_id) + ",'"+str(uidentifier)+"');"
    execute_query(connector_ids, query)
    
    if name != 'None':
        query = "insert into identities(upeople_id, identity, type)" + \
                "values(" + str(upeople_id) + ", '" + name + "', 'name');"
        execute_query(connector_ids, query)

    if email != 'None':
        query = "insert into identities(upeople_id, identity, type)" + \
                "values(" + str(upeople_id) + ", '" + email + "', 'email');"
        execute_query(connector_ids, query)
    
    query = "insert into identities(upeople_id, identity, type)" + \
            "values(" + str(upeople_id) + ", '" + user_id + "', 'user_id');"
    execute_query(connector_ids, query)

    reuse_identity(connector_its, people_id, upeople_id)
    
def search_identity(connector_ids, field):
   query = "select upeople_id from identities where identity='"+field+"'"
   results_ids = execute_query(connector_ids, query)
   return results_ids

def reuse_identity(connector_its, people_id, upeople_id):
    query = "insert into people_upeople(people_id, upeople_id) " + \
                 "values('" + str(people_id) + "', " + str(upeople_id) + ");"
    execute_query(connector_its, query)
    
def main():
   cfg = getOptions()
   
   db_bicho, connector_its = connect(cfg.db_database_its, cfg)
   db_ids, connector_ids = connect(cfg.db_database_ids, cfg)

   create_tables(db_bicho, connector_its)

   query = "select id, name, email, user_id from people"
   results = execute_query(connector_its, query)
   
   # Searching for already existing identites
   # query = "select upeople_id from identities where "
   for result in results:
      people_id = int(result[0])
      name = result[1]
      email = result[2]
      user_id = result[3]
      if name is None or name == 'None': name = ''
      else: name = name.replace("'", "\\'")  # avoiding ' errors in MySQL
      if email is None or email == 'None': email = ''
      else: email = email.replace("'", "\\'")  # avoiding ' errors in MySQL
      if user_id is None or user_id == 'None': user_id = ''
      else: user_id = user_id.replace("'", "\\'")  # avoiding ' errors in MySQL
        
      results_ids = search_identity(connector_ids, name)
      if name != '' and len(results_ids) > 0:
        print "Reusing identity by name " + name
        reuse_identity(connector_its, people_id, int(results_ids[0][0]))
        continue
      results_ids = search_identity(connector_ids, email)
      if email != '' and len(results_ids) > 0:
        print "Reusing identity by email " + email
        reuse_identity(connector_its, people_id, int(results_ids[0][0]))
        continue
      results_ids = search_identity(connector_ids, user_id)
      if user_id != '' and len(results_ids) > 0:
        print "Reusing identity by user_id " + user_id
        reuse_identity(connector_its, people_id, int(results_ids[0][0]))
        continue
      insert_identity(connector_ids, connector_its, 
                      people_id, name, email, user_id)
   db_ids.commit()
   
   # Print total people and unique people
   return 

if __name__ == "__main__":main()



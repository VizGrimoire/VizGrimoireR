#!/usr/bin/python
# -*- coding: utf-8 -*-

# This script feeds identities, upeople and upeople_countries tables 
# from a text file with emails and countries

# Copyright (C) 2013 Bitergia

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
# Author: Alvaro del Castillo <acs@bitergia.com>
# based on work by: Luis Cañas-Díaz <lcanas@bitergia.com>

from optparse import OptionParser
import MySQLdb, sys


def read_file(file):
    fd = open(file,"r")
    lines = fd.readlines()
    fd.close()
    return lines


def parse_file(file):
    idmail = []
    lines = read_file(file)
    for l in lines:
        idmail.append(l.split(","))
    return idmail


def open_database(myuser, mypassword, mydb):
    con = MySQLdb.Connect(host="127.0.0.1",
                          port=3306,
                          user=myuser,
                          passwd=mypassword,
                          db=mydb)
    #cursor = con.cursor()
    #return cursor
    return con


def close_database(con):
    con.close()


def read_options():
    parser = OptionParser(usage="usage: %prog [options]",
                          version="%prog 0.1")
    parser.add_option("-f", "--file",
                      action="store",
                      dest="countries_file",
                      default="email_country.csv",
                      help="File with email, country in format \"email,country\"")
    parser.add_option("-t", "--test",
                      action="store",
                      dest="countries_test",
                      default=False,
                      help="Generate automatic testing data")                      
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where identities table is stored")
    parser.add_option("-u", "--db-user",
                      action="store",
                      dest="dbuser",
                      default="root",
                      help="Database user")
    parser.add_option("--db-password",
                      action="store",
                      dest="dbpassword",
                      default="",
                      help="Database password")
    parser.add_option("-g", "--debug",
                      action="store_true",
                      dest="debug",
                      default=False,
                      help="Debug mode")
    (opts, args) = parser.parse_args()
    #print(opts)
    if len(args) != 0:
        parser.error("Wrong number of arguments")

    if not(opts.countries_file and opts.dbname and opts.dbuser):
        parser.error("--file and --database are needed")

    return opts


def insert_identity(cursor, debug, tuple):
    if debug:
        print("INSERT INTO identities (upeople_id, identity, type)\
        VALUES (%s, '%s', '%s')" % tuple)
    cursor.execute("INSERT INTO identities (upeople_id, identity, type)\
    VALUES (%s, '%s', '%s')" % tuple)


def insert_upeople(cursor, debug, email):
    cursor.execute("SELECT MAX(id) FROM upeople")
    maxid = cursor.fetchone()[0]
    myid = int(maxid) + 1
    if debug:
        print("INSERT INTO upeople (id, identifier) VALUES (%s, '%s')"
              % (myid, nickname))
    cursor.execute("INSERT INTO upeople (id, identifier) VALUES (%s, '%s')"
                   % (myid, email))
    return myid

def insert_upeople_country(cursor, upeople_id, country, debug):
    
    country_id = None
    query = "SELECT id FROM countries WHERE name = '%s'" % (country)
    results = cursor.execute(query)

    if results == 0:
        query = "INSERT INTO countries (name) VALUES ('%s')" % (country)
        if debug:
            print(query)
        cursor.execute(query)
        # country_id = con.insert_id()
        country_id = cursor.lastrowid
    else:
        country_id = cursor.fetchall()[0][0]
        
    cursor.execute("INSERT INTO upeople_countries (country_id, upeople_id) VALUES (%s, '%s')"
                   % (country_id, upeople_id))

    
def create_tables(cursor, con):
#   query = "DROP TABLE IF EXISTS countries"
#   cursor.execute(query)
#   query = "DROP TABLE IF EXISTS upeople_countries"
#   cursor.execute(query)

   query = "CREATE TABLE IF NOT EXISTS countries (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "name varchar(255) NOT NULL," + \
           "PRIMARY KEY (id)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8"

   cursor.execute(query)
   
   query = "CREATE TABLE IF NOT EXISTS upeople_countries (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "upeople_id int(11) NOT NULL," + \
           "country_id int(11) NOT NULL," + \
           "PRIMARY KEY (id)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8"
   cursor.execute(query)

   try:
       query = "CREATE INDEX upc_up ON upeople_countries (upeople_id);"
       cursor.execute(query)
       query = "CREATE INDEX upc_c ON upeople_countries (country_id);"
       cursor.execute(query)
   except Exception:
       print "Indexes upc_up and upc_c already created"

   con.commit()
   return

def create_test_data(cursor, opts):
    import random
    test_countries = ['country1', 'country2', 'country3', 'country4', 'country5']
    cursor.execute("DELETE FROM countries")
    cursor.execute("DELETE FROM upeople_countries")
    cursor.execute("SELECT id FROM upeople")
    identities = cursor.fetchall()
    
    for id in identities:
        country = test_countries[random.randint(0,len(test_countries)-1)]
        insert_upeople_country(cursor, id[0], country, opts.debug)    
    
if __name__ == '__main__':
    opts = None
    opts = read_options()
    con = open_database(opts.dbuser, opts.dbpassword, opts.dbname)
    
    cursor = con.cursor()
    create_tables(cursor, con)

    if opts.countries_test: # helper code to test without real data
        print("Creating test data ...")
        create_test_data(cursor, opts)
        sys.exit(0)      

    ids_file = parse_file(opts.countries_file)

    cont_new = 0
    cont_updated = 0
    cont_cached = 0
    for i in ids_file:

        email = i[0]
        email = email.replace("'", "\\'") #avoiding ' errors in MySQL
        country = i[1].rstrip('\n') #remove last \n
        
        nmatches = cursor.execute("SELECT upeople_id, type, identity \
                                  FROM identities WHERE identity = '%s'"
                                  % (email))

        if nmatches == 0:
            if opts.debug:
                print("++ %s to be inserted. New upeople tuple to be created"
                      % (str(i)))
            upeople_id = insert_upeople(cursor, opts.debug, email)
            insert_identity(cursor, opts.debug, (upeople_id, email, "email"))
            insert_upeople_country(cursor, upeople_id, country, opts.debug)
            cont_new += 1
        else:
            # there is one or more matches. There could be a lot of them!
            # if there are duplicated upeople_id we use the first we see
            identities = cursor.fetchall()
            upeople_id = identities[0][0]
            
            query = "SELECT upeople_id from upeople_countries \
                    WHERE upeople_id = '%s'" % (upeople_id)                                  
         
            nmatches = cursor.execute(query)
            
            if nmatches == 0:
                insert_upeople_country(cursor, upeople_id, country, opts.debug)
                cont_updated +=1
            else:
                cont_cached += 1
            
        con.commit()

    close_database(con)
    print("New upeople entries: %s" % (cont_new))
    print("Updated identities:  %s" % (cont_updated))
    print("Already stored identities: %s" % (cont_cached))

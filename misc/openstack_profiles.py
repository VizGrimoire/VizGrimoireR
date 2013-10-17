#!/usr/bin/python
# -*- coding: utf-8 -*-

# This script feeds OpenStack profiles from a JSON file 

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
# Authors:
#    Alvaro del Castillo <acs@bitergia.com>
#    Daniel Izquierdo <dizquierdo@bitergia.com>
#
# Data Format
#[{u'Email': u'generic@generic.com',
#  u'FirstName': u'Generic',
#  u'ID': u'9999',
#  u'IRCHandle': None,
#  u'LastEdited': u'2123-01-01 00:04:04',
#  u'OrgAffiliations': u'company.com',
#  u'OrgID': u'34',
#  u'SecondEmail': None,
#  u'Surname': u'genericsurname',
#  u'ThirdEmail': None,
#  u'TwitterName': None,
#  u'untilDate': None}]
#

from optparse import OptionParser
import MySQLdb, sys
import json
import feedparser
import pprint
import time
import sys


def connect(database, user, password):
   host = 'localhost'
   try:
      db =  MySQLdb.connect(host,user,password,database)
      return db.cursor()
   except:
      print("Database connection error")


def execute_query(connector, query):
   try:
       results = int (connector.execute(query))
   except:
       print "Error: " + query
       return[]
   cont = 0
   if results > 0:
      result1 = connector.fetchall()
      return result1
   else:
      return []



def read_file(file):
    fd = open(file,"r")
    lines = fd.read()
    fd.close()
    return lines
    
def read_options():
    parser = OptionParser(usage="usage: %prog [options]",
                          version="%prog 0.1")
    parser.add_option("-f", "--file",
                      action="store",
                      dest="profiles_file",
                      default="openstack_profiles.json",
                      help="File Open Stack profiles in JSON format")
    parser.add_option("-d", "--db-name",
                      action="store",
                      dest="dbname",
                      default="fake",
                      help="Database name where identities are updated")
    parser.add_option("-u", "--db-user",
                      action="store",
                      dest="dbuser",
                      default="root",
                      help="Database user")
    parser.add_option("-p", "--dbpassword",
                      action="store",
                      dest="dbpassword",
                      default="",
                      help="Database password")
    parser.add_option("-o", "--outfile",
                      action="store",
                      dest="outfile",
                      default="ids_companies_openstack.csv",
                      help="CSV file with identities to company mapping")
    parser.add_option("-g", "--debug",
                      action="store_true",
                      dest="debug",
                      default=False,
                      help="Debug mode")
    (opts, args) = parser.parse_args()
    #print(opts)
    if len(args) != 0:
        parser.error("Wrong number of arguments")

    if not(opts.profiles_file and opts.dbname and opts.dbuser):
        parser.error("--file and --database are needed")

    return opts

def create_csv(profiles, opts):
    print "Writing file: " + opts.outfile
    fd = open(opts.outfile,"w")
    for profile in profiles:
        if profile['OrgAffiliations'] is None: profile['OrgAffiliations']=''
        line = profile['Email']+":"+profile['OrgAffiliations']+"\n"
        fd.write(line.encode('utf-8'))
    fd.close()

    
def print_stats(profiles):
    # Some basic stats
    total = len(profiles)
    total_stats = {}
    for profile in profiles:
        for field in profile.keys():
            if not total_stats.has_key(field): total_stats[field] = 0
            if profile[field]:
                total_stats[field] = total_stats[field] + 1 
    print ("Total profiles: " + str(total))
    print ("Total stats: " + str(total_stats))


def build_query(profile):

    #json_identities=['Email', 'FirstName', 'Surname', 'SecondEmail', 'ThirdEmail', 'TwitterName', 'IRCHandle']
    json_identities=['Email', 'SecondEmail', 'ThirdEmail']
    identities = []

    for identity in json_identities:
        if profile[identity] is not None:
            identities.append(profile[identity].encode('utf-8'))

    query = "select distinct(upeople_id) from identities where "
    first = True
    for identity in identities:
        if not first:
            query = query + " or "
        query = query + " identity='"+identity+"'"
        first = False
    return query

def print_profile(profile):
    # prints specific and needed info of this profile
      
    print "Developer Profile:"
    print "    First Name:   " + profile['FirstName'].encode('utf-8')
    print "    Surname:      " + profile['Surname'].encode('utf-8')
    print "    Email:        " + profile['Email'].encode('utf-8')
    print "    Second Email: " + str(profile['SecondEmail'])
    print "    Third Email:  " + str(profile['ThirdEmail'])
    if profile['TwitterName'] is not None:
        print "    Twitter:      " + profile['TwitterName'].encode('utf-8')
    if profile['IRCHandle'] is not None:
        print "    IRC:          " + profile['IRCHandle'].encode('utf-8')
    if profile['OrgAffiliations'] is not None:
        print "    Affiliation:  " + profile['OrgAffiliations'].encode('utf-8')
    

def print_profiles_db(connector, results):
    for result in results:
        upeople_id = str(result[0])
        query = "select identity from identities where upeople_id = " + upeople_id
        identities = execute_query(connector, query)
        
        print "Profile found in DB (upeople_id = "+ upeople_id +":)"
        for identity in identities: 
            print "    Identity:    **" + identity[0] + "**"

        query = "select c.name, upc.init, upc.end " +\
                "from upeople_companies upc, companies c " +\
                "where upc.company_id = c.id and upc.upeople_id = " + upeople_id
        affiliations = execute_query(connector, query)
        for aff in affiliations:
            print "    Affiliation: " + str(aff[0]) + ", Init: " + str(aff[1]) + ", End: " + str(aff[2])

def insert_new_aff(connector, company, upeople_id):
    company = company[:-1]
    query = "select id from companies where name like '%"+company+"%'"
    print query
    company_id = execute_query(connector, query)
    print len(company_id)
    print company_id
    if len(company_id) == 0:
        # company does not exist
        query = "select max(id) from companies"
        max_company_id = execute_query(connector, query)
        max_id = str(int(max_company_id[0][0]) + 1)
        query = "insert into companies(id, name) values("+max_id+", '"+company+"')"
        print query
        execute_query(connector, query)
        company_id = max_id
        print "New Company inserted: " + company + " with id: " + max_id
    else:
        company_id = str(int(company_id[0][0]))

    query = "insert into upeople_companies(upeople_id, company_id, init, end) " +\
            "values("+upeople_id+", "+company_id+", '1900-01-01', '2100-01-01')"
    print query
    execute_query(connector, query)

def check_profiles_db(connector, results, profile):
    for result in results:
        upeople_id = str(result[0])
        query = "select distinct(i.identity) from identities i, people_upeople pup " +\
                "where pup.upeople_id = i.upeople_id and i.upeople_id = " + upeople_id
        identities = execute_query(connector, query)

        if len(identities) > 0:
            print "\n\nProfile found in DB and in CVSAnalY (upeople_id = "+ upeople_id +")"
            for identity in identities:
                print "    Identity:    **" + identity[0] + "**"

            print_profile(profile)
            query = "select c.name, upc.init, upc.end " +\
                    "from upeople_companies upc, companies c " +\
                    "where upc.company_id = c.id and upc.upeople_id = " + upeople_id
            affiliations = execute_query(connector, query)
            print "DB Affiliations"
            for aff in affiliations:
                print "    DB Affiliation: " + str(aff[0]) + ", Init: " + str(aff[1]) + ", End: " + str(aff[2])
            print ("Specify company to insert: "),
            company = sys.stdin.readline()
            print "Selected company: **" + str(company[:-1]) + "**"
            if len(company) == 1:
                continue
            else:
                insert_new_aff(connector, company, upeople_id) 
    


def update_db(profiles):
    # updates cvsanaly format database
    
    connector = connect(opts.dbname, opts.dbuser, opts.dbpassword)
    for profile in profiles:

        #print_profile(profile)

        query = build_query(profile)
        results = execute_query(connector, query)

        #print_profiles_db(connector, results)

        check_profiles_db(connector, results, profile)
    

if __name__ == '__main__':
    opts = None
    opts = read_options()
    
    print(opts.profiles_file)
        
    profiles = json.loads(read_file(opts.profiles_file))
    
    print_stats(profiles)
    
    #create_csv(profiles, opts)
    
    update_db(profiles)
    

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
#       Jesus M. Gonzalez-Barahona <jgb@gsyc.es>

#
# checkaffiliation.py
#
# Checks tables related to affiliation to companies:
# upeople_companies and companies
#
# General idea about the affiliation tables:
# Unique people (that is, individual persons, who could have several
# identities) are in upeople table.
#
# Companies are in companies table. In addition, that table also holds:
#  - Special company name "-Unknown", for people with unknown affiliation
#  - Special company name "-Bot", for bots
#  - Special company name "-Individual", for people known to work on
#     their own, not affiliated to any company
#
# The relationship between companies and upeople is in upeople_companies.
# This table has one entry per developer affiliated to a company during
# a certain period.
# Date "1900-01-01" means "since always" (no starting date)
# Date "2100-01-01" means "for ever" (no finishing date)
#
# This script looks for potential inconsistencies, such as:
# People in more than one company during the same period
#  (an special case is when one of the companies is "-Unknown",
#   for sure that's an error)
# People with no affilaition (not even -Unknown")

# Parsing command line arguments
import argparse
# Communication with MySQL
import MySQLdb
import datetime

def ShowAll ():
    """Show all entries in upeople_companies table"""

    query = """SELECT identifier, companies.name, upeople_companies.*
FROM upeople_companies, companies, upeople
WHERE company_id = companies.id and
  upeople_id = upeople.id
ORDER BY upeople.id;"""

    cursor.execute(query)
    upeopleCompanies = cursor.fetchall()

    print "== All entries:"
    print
    for entry in upeopleCompanies:
        (person, company, id, personId, companyId, start, end) = entry
        print person + " (" + company + ") " + str(start) + ", " + str(end)

def CheckOverlap (entries):
    """Checks if entries in upeople_companies overlap.

    - entries: dictionary with entries in upeople_companies
       Usually they are entries for the same person
       Key is the id in upeople_companies table.
       Value is a list with company, start, end

    Returns True if there is overlap, False if not
    """

    events = []
    for id in entries.keys():
        (company, start, end) = entries[id]
        events.append ((start, company, "start"))
        # End is minored in one sec. because end time could be
        # equal than starting time for next company
        events.append ((end - datetime.timedelta(seconds=1),
                        company, "end"))
    # Sort by date (element 0 of tuplas), in place
    events.sort(key=lambda tup: tup[0])
    company = ""
    started = False
    for event in events:
        if started:
            if (event[2] != "end") or (event[1] != company):
                return (True)
            else:
                started = False
        else:
            company = event[1]
            started = True
    return (False)

def printEntries (person, entries, overlap):
    """Print entries from upeople_companies for person (ordered).

    - person (String): name of person (upeople) corresponding to entries
    - entries: dictionary with entries in upeople_companies
       Usually they are entries for the same person
       Key is the id in upeople_companies table.
       Value is a list with company, start, end
    - overlap (Boolean): do these entries have some overlapping period?
    """

    toprint = []
    for id in entries.keys():
        (company, start, end) = entries[id]
        toprint.append ((start,
                         str(overlap) + ": [" + str(start) + " - " + \
                             str(end) + "] " + person + ", " + \
                             company
                         ))
    toprint.sort(key=lambda tup: tup[0])
    for line in toprint:
        print line[1]

def ShowDups (dates=False):
    """Show upeople with more than one entry in upeople_companies.
    
    - dates (Boolean): show entries only when dates for same upeople 
       overlap
    """

    query = """SELECT identifier, companies.name, upeople_companies.*
FROM upeople_companies, companies, upeople,
  (
  SELECT upeople_id FROM upeople_companies
  GROUP BY upeople_id HAVING count(id) > 1
  ) dup
WHERE upeople_companies.upeople_id = dup.upeople_id AND
  company_id = companies.id and
  upeople_companies.upeople_id = upeople.id
ORDER BY upeople.id"""

    cursor.execute(query)
    dupUpeopleCompanies = cursor.fetchall()

    print
    print "== Duplicate entries (person more than once):"
    print
    currentPerson = ""
    currentEntries = {}
    for entry in dupUpeopleCompanies:
        (person, company, id, personId, companyId, start, end) = entry
        if dates:
            if person != currentPerson:
                if currentPerson != "":
                    overlap = CheckOverlap (currentEntries)
                    printEntries (currentPerson, currentEntries, overlap)
                currentPerson = person
                currentEntries = {}
            currentEntries[id] = (company, start, end)
        else:
            print person + " (" + company + ") " + str(start) + \
                ", " + str(end)
    if dates:
        print currentPerson, currentEntries

# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--database",
                    help="Database to check")
parser.add_argument("--user",
                    help="Database user name")
parser.add_argument("--passwd",
                    help="Dagtabase password")
parser.add_argument("--showall",
                    help="Show all entries in upeople_companies",
                    action="store_true")
parser.add_argument("--showdups",
                    help="Show upeople with more than one entry in upeople_companies",
                    action="store_true")
parser.add_argument("--showoverlap",
                    help="Show upeople with overlapping entries in upeople_companies",
                    action="store_true")
args = parser.parse_args()

# Open database connection
db = MySQLdb.connect(user=args.user, passwd=args.passwd,
                     db=args.database)
# Uncomment these lines and specify options for the database access
# db = MySQLdb.connect(host = "xxx",
#                      user = "xxx",
#                      port = 3308,
#                      db = "xxx")

cursor = db.cursor()
# Set all name retrieval in utf8
cursor.execute("SET NAMES utf8")


if args.showall:
    ShowAll()
if args.showdups:
    ShowDups()
if args.showoverlap:
    ShowDups(True)

db.close()

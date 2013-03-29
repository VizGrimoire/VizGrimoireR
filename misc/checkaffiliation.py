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

def CheckExact (entries):
    """Checks if entries in upeople_companies are exactly equal.

    - entries: dictionary with entries in upeople_companies
       Usually they are entries for the same person
       Key is the id in upeople_companies table.
       Value is a list with company, start, end
    Returns tuple (found, id):
      - found: True if exact match was found, False otherwise
      - id: id of exact match if there is exactly an equal entry,
         If are more than two equal entries, only the second one
         is returned (the first one is considered as the "original")
         None if no exact match was found.
    """

    ids = sorted(entries.keys())
    if len(ids) == 1:
        return (False, None)
    for pos in range (0, len(ids)-1):
        for other in range (pos+1, len(ids)):
            if entries[ids[pos]] == entries[ids[other]]:
                return (True, ids[other])
    return (False, None)

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
                         str(overlap) + " (" + str(id) + "): [" + \
                             str(start) + " - " + \
                             str(end) + "] " + person + ", " + \
                             company
                         ))
    toprint.sort(key=lambda tup: tup[0])
    for line in toprint:
        print line[1]

def ShowDups (overlap=False, exact=False):
    """Show upeople with more than one entry in upeople_companies.
    
    - overlap (Boolean): show entries only when dates for same upeople 
       overlap
    - exact (Boolean): show only entries which are exactly equal
       (same company, same dates)
    Returns a list of rows to delete from upeople_companies,
     Rows to delete are duplicated rows, with exact match.
     The list may be empty.
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

    todelete = []
    cursor.execute(query)
    dupUpeopleCompanies = cursor.fetchall()

    print
    print "== Overlapped entries (person with overlapped affiliations):"
    print
    currentPerson = ""
    currentEntries = {}
    for entry in dupUpeopleCompanies:
        (person, company, id, personId, companyId, start, end) = entry
        if overlap or exact:
            if person != currentPerson:
                if currentPerson != "":
                    if exact:
                        (found, foundid) = CheckExact (currentEntries)
                        if found:
                            todelete.append(foundid)
                    elif overlap:
                        found = CheckOverlap (currentEntries)
                    printEntries (currentPerson, currentEntries, found)
                currentPerson = person
                currentEntries = {}
            currentEntries[id] = (company, start, end)
        else:
            print person + " (" + company + ") " + str(start) + \
                ", " + str(end)
    if exact:
        (found, foundid) = CheckExact (currentEntries)
        if found:
            todelete.append(foundid)
    elif overlap:
        found = CheckOverlap (currentEntries)
    if overlap or exact:
        printEntries (currentPerson, currentEntries, found)
    return (todelete)

def ShowUnaffiliated ():
    """Show upeople with no entry in upeople_companies (unaffilated).
    """

    query = """SELECT upeople.*
FROM upeople
LEFT JOIN upeople_companies
ON upeople.id = upeople_companies.upeople_id
WHERE upeople_companies.upeople_id IS NULL
"""

    cursor.execute(query)
    unaffilatedUpeople = cursor.fetchall()

    print
    print "== Unaffilated upeople:"
    print
    for entry in unaffilatedUpeople:
        (id, name) = entry
        print str(id) + ": " + str(name)

#
# Starts main program
#

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
parser.add_argument("--showexact",
                    help="Show exactly repeated entries in upeople_companies. Will delete duplicates (only the first duplicate for each row) if --modify is used",
                    action="store_true")
parser.add_argument("--showunaffiliated",
                    help="Show unaffilaited upeople",
                    action="store_true")
parser.add_argument("--modify",
                    help="Modify the database. If not present, just print the SQL code instead of modifying the database",
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
    ShowDups(overlap=True)
if args.showexact:
    todelete = ShowDups(exact=True)
if args.showunaffiliated:
    ShowUnaffiliated()

# Modify the database, or just print the SQL code for it
#  (according to the --modify flag)
for id in todelete:
    sql = "DELETE FROM upeople_companies WHERE id = " + str(int(id))
    print sql,
    if args.modify:
        print " Deleting...",
        cursor.execute (sql)
        db.commit()
        print " Deleted!",
    print

db.close()

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

import MySQLdb

# Open database connection and get all data in people table
# into people list.
# Uncomment these lines and specify options for the database access
# db = MySQLdb.connect(host = "xxx",
#                      user = "xxx",
#                      port = 3308,
#                      db = "xxx")
db = MySQLdb.connect(user="jgb", passwd="XXX",
                     db="dic_cvsanaly_openstack_1289_updated")

cursor = db.cursor()
# Set all name retrieval in utf8
cursor.execute("SET NAMES utf8")

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
for entry in dupUpeopleCompanies:
    (person, company, id, personId, companyId, start, end) = entry
    print person + " (" + company + ") " + str(start) + ", " + str(end)


db.close()

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
#   Jesus M. Gonzalez-Barahona <jgb@gsyc.es>
#	Daniel Izquierdo-Cortazar <dizquierdo@bitergia.com>

#
# unifypeople.py
#
# This is just a first try at a code for "unifying" uids in the people
# table created by CVSAnalY. It creates two tables:  people_upeople, which has
# people_id (id in people) and upeople_id, same id if unique, or "cannonical" id if
# duplicated. Cannonical id is considered to be the lower id in people.
# The second table is upeople which is a list of that "cannonical" ids.
#
# Most of the work is actually done by the Identities class, which is
# designed to store a kind of identities (names, email addresses, etc.)
# It offers several different methods for finding duplicate identities
# of that kind
#

import MySQLdb
from optparse import OptionGroup, OptionParser

class Identities:
    """Keeps track of identities assigned to unique ids.

    Allow for storing identities pointing to unique ids,
    and to check if an identity is already assigned to a unique id.
    Identities may be names, email addresses, etc.
    Maintains identities in lowercase, to "unify" them.
    """

    def find (self, identity):
        """Returns the unique id for an identity, or 0 if not found"""

        identity = identity.lower()
        if identity in self.stored:
            return (self.stored[identity])
        else:
            return (0)

    def findDotted (self, identity):
        """Tries to find likely email addresses.

        Finds the identity lowercased, with dots instear of spaces,
        and compared to anything before @. We compare only in cases
        of strings with spaces or dots (otherwise, too much false
        positives).
        Returns the unique id for an identity, or 0 if not found"""

        if (' ' in identity) or ('.' in identity):
            identity = identity.lower().replace(' ', '.')
        else:
            print "**Not checking: " + identity
            return (0)
        for element in sorted(self.stored):
            if identity == element.split('@',1)[0]:
                print "**Found: " + identity + " / " + element
                return (self.stored[element])
        return (0)

    def insert (self, identity, uid):
        """Inserts the unique id for an identity"""

        identity = identity.lower()
        self.stored[identity] = uid

    def get_all (self):
        """Get all identities, sorted"""

        return (sorted(self.stored.keys()))

    def print_all (self, tag = ""):
        """Print all identities, one per line, sorted

        tag: tag to write at the beginning of each line."""

        for identity in self.get_all():
            print tag + identity + "."

    def __init__ (self):
        """Create the dictionary for stored identities.

        Key for the dictionary is identity, value is unique id.
        """

        self.stored = {}

def strPerson (person):
    """Get a string out of a (name,email) dictionary."""

    return (person['name'] + " / " + person['email'])

def getOptions():     
    parser = OptionParser(usage='Usage: %prog [options]', 
                          description='Unify identities',
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
    parser.add_option('-i', '--incremental', dest='incremental',
                      help='yes/no incremental analysis', default='yes')
    
    (ops, args) = parser.parse_args()
    
    return ops
    

def generate_upeople(personsById):
    upeople = []
    for id in sorted(personsById):
        if id in dupIds:
            uid = dupIds[id]
        else:
            uid = id
        upeople.append((id, uid))

    return upeople


def create_schema(cursor, db, upeople):

    print "Now creating people_upeople table (this may take a while)..."
    cursor.execute("DROP TABLE IF EXISTS people_upeople")
    cursor.execute("""CREATE TABLE people_upeople (
                               people_id int(11) NOT NULL,
                               upeople_id int(11) NOT NULL,
                               PRIMARY KEY (people_id)
                  ) ENGINE=MyISAM DEFAULT CHARSET=utf8""")
    cursor.execute("ALTER TABLE people_upeople DISABLE KEYS")
    db.commit()

    cursor.executemany("""INSERT INTO people_upeople (people_id, upeople_id)
       VALUES (%s, %s)""", upeople)
    cursor.execute("ALTER TABLE people_upeople ENABLE KEYS")
    db.commit()

    # Creating table upeople with a list of unique ids.
    cursor.execute("DROP TABLE IF EXISTS upeople")
    cursor.execute("""CREATE TABLE upeople(id int(11) NOT NULL,
                                       identifier varchar(128),
                                       PRIMARY KEY (id))
                      ENGINE=MyISAM DEFAULT CHARSET=utf8""")
    db.commit()
    cursor.execute("""INSERT INTO upeople(id) 
                  SELECT DISTINCT(upeople_id) from people_upeople""")

    # Creating identities table
    cursor.execute("DROP TABLE IF EXISTS identities")
    cursor.execute("""CREATE TABLE identities (id int(11) NOT NULL AUTO_INCREMENT, 
                                           upeople_id int(11) NOT NULL,
                                           identity VARCHAR(256) NOT NULL,
                                           type VARCHAR(24),
                                           PRIMARY KEY(id))
                      ENGINE=MyISAM DEFAULT CHARSET=utf8""")
    db.commit()
    cursor.execute("""INSERT INTO identities(upeople_id, identity)
                             SELECT distinct u.id, 
                                    p.name 
                             FROM people p, 
                                  people_upeople pup, 
                                  upeople u 
                             WHERE p.id=pup.people_id and 
                                   pup.upeople_id=u.id 
                             ORDER by u.id""")
    cursor.execute("""UPDATE identities set type='name'
                      WHERE type is null""")
    db.commit()
    cursor.execute("""INSERT INTO identities(upeople_id, identity)
                             SELECT distinct u.id, 
                                    p.email 
                             FROM people p, 
                                  people_upeople pup, 
                                  upeople u 
                             WHERE p.id=pup.people_id and 
                                   pup.upeople_id=u.id 
                             ORDER by u.id""")
    cursor.execute("""UPDATE identities set type='email'
                      WHERE type is null""")
    db.commit()

    #Finally, updating field identifier in upeople table taking a random name
    cursor.execute("""UPDATE upeople u, 
                              identities i 
                      SET u.identifier=i.identity 
                      WHERE u.id = i.upeople_id and
                            i.type='name'""")
    db.commit() 

def execute_query(cursor, query):
    results = int (cursor.execute(query))
    cont = 0
    if results > 0:
        result1 = cursor.fetchall()
        return result1
    else:
        return []

def check_tables(cursor):
    tables_exist = True
    try:
        execute_query(cursor, "select count(*) from people_upeople limit 1")      
    except Exception:
        tables_exist = False
    return tables_exist


def update_schema(cursor, db, upeople):
  
    query = """select distinct p.id, p.name, p.email 
               from people p 
               where p.id not in 
                     (select distinct people_id 
                      from people_upeople);"""

    results = execute_query(cursor, query)
    print results
    for result in results:
        print result
        # check if the algorithm was able to detect duplicated identities
        # with this set of developers. This is done, checking if the people_id
        # is different from the upeople_id in the tuple upeople
        for person in upeople:
            if int(result[0]) == int(person[0]):
                #This is one of the new comers to the community
                if int(person[0]) <> int(person[1]):
                    # a new identity for a developer was found by the algorithm
                    query = "insert into people_upeople(people_id, upeople_id) " +\
                            " values(" + str(person[0]) + ", " + str(person[1]) + ")"
                    execute_query(cursor, query)
                    #To be fixed: this action will probably introduce repeated emails or names
                    #at some point
                    query = "INSERT INTO identities(upeople_id, identity, type) " +\
                            " values(" + str(person[1]) + ", '" + result[1] + "', 'name')"
                    execute_query(cursor, query)
                    query = "INSERT INTO identities(upeople_id, identity, type) " +\
                            " values(" + str(person[1]) + ", '" + result[2] + "', 'email')"
                else:
                    query = "select max(id) from upeople"
                    values = execute_query(cursor, query)
                    max_id = int(values[0][0]) + 1
                    # a new developer has been found by the algorithm
                    query = "insert into people_upeople(people_id, upeople_id) " +\
                            " values(" + str(person[0]) + ", " + str(max_id) + ")"
                    execute_query(cursor, query)
                    query = "insert into upeople(id, identifier) " +\
                            " values(" + str(max_id) + ", '" + str(result[1]) + "')"
                    execute_query(cursor, query)
                    query = "INSERT INTO identities(upeople_id, identity, type) " +\
                            " values(" + str(max_id) + ", '" + result[1] + "', 'name')"
                    execute_query(cursor, query)
                    query = "INSERT INTO identities(upeople_id, identity, type) " +\
                            " values(" + str(max_id) + ", '" + result[2] + "', 'email')"
                    execute_query(cursor, query)
                    
                    
# Open database connection and get all data in people table
# into people list.

cfg = getOptions()

incremental = True
if cfg.incremental == 'no':
    incremental = False

db = MySQLdb.connect(user = cfg.db_user, passwd = cfg.db_password,  db = cfg.db_database)

cursor = db.cursor()

if (check_tables(cursor) == False):
    print("Tables does not exists. Incremental off")
    incremental = False

query = """SELECT *
           FROM people, scmlog
           WHERE people.id = scmlog.author_id
           GROUP BY people.id"""

query = "SELECT * FROM people"

# Hack for wikimedia. https://www.bitergia.net/redmine/issues/2428
query = "SELECT * FROM people WHERE email<>'ttijhof@wikimedia.org'"

# Set all name retrieval in utf8
cursor.execute("SET NAMES utf8")
# execute SQL query using execute() method.
cursor.execute(query)
people = cursor.fetchall()

# Create objects for checking identities
identitiesNames = Identities()
identitiesEmails = Identities()
# Entries in people, as a dictionary keyed by id
personsById = {}
# Ids that are duplicate. Key is the id, value is the "original" id,
#  which we use as unique id (it is the lower one of the dups)
dupIds = {}

# Now, check all identities in persons
for person in people:
    try:
        (id, name, email) = person
    except:
        # Not a cvsanaly db just create empty tables
        break
    # In Linux kernel, there are several "???", "", etc. names
    # Let's substitute them for something meaningful (the id)
    if name in ("???", "?", "", "root"):
        name = "**Unknown**" + "%3d" % id
    personsById[id] = {'name': name, 'email': email}
    # Is name in names?
    uidName = identitiesNames.find (name)
    if uidName == 0:
        identitiesNames.insert (name, id)
    # Is name in emails? (probably it is actually an email)
    uidNameEmail = identitiesEmails.find (name)
    # Is name, lowercased and dotted, in emails?
    #uidNameEmailDotted = identitiesEmails.findDotted (name)
    # Is email in emails?
    if email == "":
        uidEmail = 0
    else:
        uidEmail = identitiesEmails.find (email)
    if uidEmail == 0:
        identitiesEmails.insert (email, id)
    #foundIds = [uidName, uidNameEmail, uidEmail, uidNameEmailDotted]
    foundIds = [uidName, uidNameEmail, uidEmail]
    foundIds = [el for el in foundIds if el != 0]
    foundIds = sorted (list (set (foundIds)))
    if len(foundIds) > 0:
        # There is at least one duplicate. First one is the "unique"
        duplicates = foundIds[1:]
        duplicates.append(id)
        for dup in duplicates:
            dupIds[dup] = foundIds[0]


# Uncomment next lines for debugging results

#for id in sorted(dupIds):
#    print str(id) + " (" + strPerson(personsById[id]) + \
#        ") is a duplicate of " + \
#        str(dupIds[id]) + " (" + strPerson(personsById[dupIds[id]]) + ")"
#print "== Names =="
#identitiesNames.print_all("Name: ")
#print "== Email addresses =="
#identitiesEmails.print_all(":Email: ")
print str(len(dupIds)) + " duplicate ids found."

# Create unique people table
# Each row is a people identifier, and a unique identifier
# Several people identifiers could have the same unique identifier

upeople = generate_upeople(personsById)
if not incremental:
    create_schema(cursor, db, upeople)
else:
    update_schema(cursor, db, upeople)



db.close()
print "Done."
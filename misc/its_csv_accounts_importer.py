#!/usr/local/bin/python
# -*- coding: utf-8 -*-

# This script feeds identity and upeople table from a text file with
# nicknames from ITS and emails

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
# Author: Luis Cañas-Díaz <lcanas@bitergia.com>

from optparse import OptionParser
import MySQLdb
import sys


def read_file(path_file):
    fd = open(path_file)
    lines = fd.readlines()
    fd.close()
    return lines


def parse_file(url_file):
    idnamemail = []
    lines = read_file(url_file)
    for l in lines:
        fields = l.split(',')
        aux = []
        aux.append(fields[1].replace('"',''))
        aux.append(fields[2].replace('"',''))
        aux.append(fields[3].replace('"','').replace('\n',''))
        idnamemail.append(aux)
        #print aux
    return idnamemail


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
                      dest="url_file",
                      help="Path of file with ITS ids in cvs format")
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where people table is stored")
    parser.add_option("--db-user",
                      action="store",
                      dest="dbuser",
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

    if not(opts.url_file and opts.dbname and opts.dbuser):
        parser.error("Wrong options")

    return opts


def insert_identity(cursor, debug, tuple):
    if debug:
        print("INSERT INTO identities (upeople_id, identity, type)\
        VALUES (%s, '%s', '%s')" % tuple)
    cursor.execute("INSERT INTO identities (upeople_id, identity, type)\
    VALUES (%s, '%s', '%s')" % tuple)


def insert_upeople(cursor, debug, nickname):
    cursor.execute("SELECT MAX(id) FROM upeople")
    maxid = cursor.fetchone()[0]
    myid = int(maxid) + 1
    if debug:
        print("INSERT INTO upeople (id, identifier) VALUES (%s, '%s')"
              % (myid, nickname))
    cursor.execute("INSERT INTO upeople (id, identifier) VALUES (%s, '%s')"
                   % (myid, nickname))
    return myid


def id_is_unique(identities):
    unique_uids = []
    for idb in identities:
        upeople_id = idb[0]
        unique_uids.append(upeople_id)
    nids = len(set(unique_uids))

    if nids == 1:
        return True
    else:
        return False


if __name__ == '__main__':
    opts = None
    opts = read_options()
    ids_file = parse_file(opts.url_file)
    con = open_database(opts.dbuser, opts.dbpassword, opts.dbname)
    cursor = con.cursor()
    cont_new = 0
    cont_updated = 0
    cont_cached = 0
    
    for i in ids_file:
        nickname = i[0]
        name = i[1]
        email = i[2]

        #nmatches = cursor.execute("SELECT * FROM people WHERE user_id = '%s'"
        #                          % (nickname))
        nmatches = cursor.execute("UPDATE people \
                                   SET name = \"%s\", email = \"%s\" \
                                   WHERE user_id = '%s'"
                                   % (name, email, nickname))
        print("%s matches for id %s" % (str(nmatches), nickname))
        if nmatches == 0:
            cont_new += 1
        else:
            cont_updated += 1
            
    print("Entries not included: %s" % (cont_new))
    print("Updated identities:  %s" % (cont_updated))
    #print("Already stored identities: %s" % (cont_cached))            

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
import urllib2
import MySQLdb


def read_file(url_file):
    fd = urllib2.urlopen(url_file)
    lines = fd.readlines()
    fd.close()
    return lines


def parse_file(url_file):
    idmail = []
    lines = read_file(url_file)
    for l in lines:
        idmail.append(l.split())
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
                      dest="url_file",
                      default="https://raw.github.com/markmc/openstack-gitdm/master/openstack-config/launchpad-ids.txt",
                      help="URL of file with ITS ids in format \"ID EMAIL\"")
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where identities table is stored")
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
        email = i[1]

        nmatches = cursor.execute("SELECT upeople_id, type, identity \
                                  FROM identities WHERE identity = '%s' \
                                  OR identity = '%s'"
                                  % (nickname, email))

        if nmatches == 0:
            if opts.debug:
                print("++ %s to be inserted. New upeople tuple to be created"
                      % (str(i)))
            upeople_id = insert_upeople(cursor, opts.debug, nickname)
            insert_identity(cursor, opts.debug, (upeople_id, nickname, "its"))
            insert_identity(cursor, opts.debug, (upeople_id, email, "email"))
            cont_new += 1

        else:
            # there is one or more matches. There could be a lot of them!
            # if there are duplicated upeople_id we use the first we see
            identities = cursor.fetchall()
            upeople_id = identities[0][0]
            inserted = False

            m = cursor.execute("SELECT * FROM identities \
                               WHERE identity = '%s' AND type = 'its'"
                               % (nickname))
            if m == 0:
                insert_identity(cursor, opts.debug, (upeople_id, nickname, "its"))
                inserted = True

            n = cursor.execute("SELECT * FROM identities \
                               WHERE identity = '%s' AND type = 'email'"
                               % (email))
            if n == 0:
                insert_identity(cursor, opts.debug, (upeople_id, email, "email"))
                inserted = True

            if (m > 0) and (n > 0):
                if opts.debug:
                    print("upeople_id %s already stored" % (str(upeople_id)))
                cont_cached += 1

            if not id_is_unique(identities):
                # dup upeople_id
                ilist = set()
                for i in identities:
                    upeople_id = i[0]
                    ilist.add(upeople_id)
                print("[!] Manual intervetion needed for duplicated upeople_id: %s"
                      % (str(list(ilist))))

            if inserted:
                cont_updated += 1

        con.commit()

    close_database(con)
    print("New upeople entries: %s" % (cont_new))
    print("Updated identities:  %s" % (cont_updated))
    print("Already stored identities: %s" % (cont_cached))

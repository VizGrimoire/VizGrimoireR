#!/usr/bin/python
# -*- coding: utf-8 -*-

# This script parse IRC logs from Wikimedia 
# and store them in database

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

from optparse import OptionParser
import os, sys
import MySQLdb


def read_file(file):
    fd = open(file, "r")
    lines = fd.readlines()
    fd.close()
    return lines


def parse_file(file):
    date_nick_message = []
    lines = read_file(file)
    for l in lines:
        # [12:39:15] <wm-bot>  Infobot disabled
        aux = l.split(" ")
        time = aux[0]
        time = time[1:len(time) - 1]
        nick = (aux[1].split("\t"))[0]
        nick = nick[1:len(nick) - 1]
        msg = ' '.join(aux[2:len(aux)])
        date_nick_message.append([time, nick, msg])
    return date_nick_message


def open_database(myuser, mypassword, mydb):
    con = MySQLdb.Connect(host="127.0.0.1",
                          port=3306,
                          user=myuser,
                          passwd=mypassword,
                          db=mydb)
    # cursor = con.cursor()
    # return cursor
    return con


def close_database(con):
    con.close()


def read_options():
    parser = OptionParser(usage="usage: %prog [options]",
                          version="%prog 0.1")
    parser.add_option("--dir",
                      action="store",
                      dest="data_dir",
                      default="irc",
                      help="Directory with all IRC logs")
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where identities table is stored")
    parser.add_option("--db-user",
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
    # print(opts)
    if len(args) != 0:
        parser.error("Wrong number of arguments")

    if not(opts.data_dir and opts.dbname and opts.dbuser):
        parser.error("--dir and --database are needed")

    return opts

def escape_string (message):
    if "\\" in message:
        message = message.replace("\\", "\\\\")
    if "'" in message:    
        message = message.replace("'", "\\'")
    return message
 

def insert_message(cursor, date, nick, message):
    message = escape_string (message)
    nick = escape_string (nick)
    q = "insert into irclog (date,nick,message) values (";
    q += "'" + date + "','" + nick + "','" + message + "')"
    cursor.execute(q)
    
def create_tables(cursor, con):
    query = "DROP TABLE IF EXISTS irclog"
    cursor.execute(query)

    query = "CREATE TABLE IF NOT EXISTS irclog (" + \
           "id int(11) NOT NULL AUTO_INCREMENT," + \
           "nick VARCHAR(255) NOT NULL," + \
           "date DATETIME NOT NULL," + \
           "message TEXT," + \
           "PRIMARY KEY (id)" + \
           ") ENGINE=MyISAM DEFAULT CHARSET=utf8"
    cursor.execute(query)

    query = "CREATE INDEX ircnick ON irclog (nick);"
    cursor.execute(query)
   
    con.commit()
    return
    


if __name__ == '__main__':
    opts = None
    opts = read_options()
    # ids_file = parse_file(opts.countries_file)
    con = open_database(opts.dbuser, opts.dbpassword, opts.dbname)
        
    
    cursor = con.cursor()
    create_tables(cursor, con)

    count_msg = 0
    files = os.listdir(opts.data_dir)
    for logfile in files:
        year = logfile[0:4]
        month = logfile[4:6]
        day = logfile[6:8]    
        date = year + "-" + month + "-" + day
        date_nick_msg = parse_file(opts.data_dir + "/" + logfile)

        for i in date_nick_msg:
            insert_message (cursor, date + " " + i[0], i[1], i[2])                
            count_msg += 1
            if (count_msg % 1000 == 0): print (count_msg)
        con.commit()

    close_database(con)
    print("Total messages: %s" % (count_msg))
    sys.exit(0)
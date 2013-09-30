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
# Data Format
#[{u'Email': u'wenyuan.cai@gmail.com',
#  u'FirstName': u'Wenyuan',
#  u'ID': u'7409',
#  u'IRCHandle': None,
#  u'LastEdited': u'2013-01-29 20:42:47',
#  u'OrgAffiliations': u'Hypers.com',
#  u'OrgID': u'1402',
#  u'SecondEmail': None,
#  u'Surname': u'Cai',
#  u'ThirdEmail': None,
#  u'TwitterName': None,
#  u'untilDate': None}]
#
# Author: Alvaro del Castillo <acs@bitergia.com>

from optparse import OptionParser
import MySQLdb, sys
import json
import feedparser
import pprint



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
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where identities table is stored")
    parser.add_option("-u", "--db-user",
                      action="store",
                      dest="dbuser",
                      default="root",
                      help="Database user")
    parser.add_option("-p", "--db-password",
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

    if not(opts.profiles_file and opts.dbname and opts.dbuser):
        parser.error("--file and --database are needed")

    return opts
    
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


if __name__ == '__main__':
    opts = None
    opts = read_options()
    
    print(opts.profiles_file)
        
    profiles = json.loads(read_file(opts.profiles_file))
    
    print_stats(profiles)
    
    
    
#!/usr/bin/env python

# Copyright (C) 2014 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# This file is a part of the vizGrimoire package
#
## Authors:
## Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
#
# Example of use: PYTHONPATH=../vizgrimoire:../vizgrimoire/analysis LANG= ./mls-studies.py 
#                  --identities <database> --mls <database> -d 2013-01-01 -e 2013-01-31
#

import logging
import sys
import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds
from optparse import OptionParser
from threads import Threads
import MLS

def read_options():
    parser = OptionParser(usage="usage: %prog [options]",
                          version="%prog 0.1")
    parser.add_option("-u","--dbuser",
                      action="store",
                      dest="dbuser",
                      default="root",
                      help="Database user")
    parser.add_option("-p","--dbpassword",
                      action="store",
                      dest="dbpassword",
                      default="",
                      help="Database password")
    parser.add_option("-m", "--mls",
                      action="store",
                      dest="dbmls",
                      help="MLS database")
    parser.add_option("-t", "--identities",
                      action="store",
                      dest="dbidentities",
                      help="Identities database")
    parser.add_option("-d", "--initdate",
                      action="store",
                      dest="initdate",
                      help="Initial date of analysis")
    parser.add_option("-e", "--enddate",
                      action="store",
                      dest="enddate",
                      help="Final date of analysis")
    parser.add_option("-o", "--destdir",
                      action="store", 
                      dest="destdir",
                      help="Output dir of JSON files")
    (opts, args) = parser.parse_args()

    if len(args) != 0:
        parser.error("Wrong number of arguments")

    if not(opts.dbidentities and opts.dbuser):
        parser.error("--dbuser and --dbidentities are needed")
    return opts


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting Studies analysis")
    opts = read_options()
   
    GrimoireSQL.SetDBChannel (database=opts.dbmls, user=opts.dbuser, password=opts.dbpassword)
    startdate = opts.initdate
    enddate = opts.enddate
    identities_db = opts.dbidentities

    main_topics = Threads(startdate, enddate, identities_db)

    # Example of use for the most verbose thread
    #email = main_topics.verboseThread()
    #print "The most verbose thread: "
    #print """
    #          message_id: %s
    #          subject: %s
    #          date: %s
    #          """ % (email.message_id, email.subject, email.date)

    # WARNING: This code for senders overwrite previous mls-top.json file
    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','','Translation updater bot','jenkins-bot']

    top_data = {}
    print startdate
    top_data['senders.'] = MLS.top_senders(0, "'"+startdate+"'", "'"+enddate+"'", identities_db, bots, "30")
    top_data['senders.last year'] = MLS.top_senders(365, "'"+startdate+"'", "'"+enddate+"'", identities_db, bots, "30")
    top_data['senders.last month'] = MLS.top_senders(31, "'"+startdate+"'", "'"+enddate+"'", identities_db, bots, "30")


    # Top longest threads during the whole life of the project
    longest_threads = main_topics.topLongestThread(10)
    print "Top longest threads: " 
    l_threads = {}
    l_threads['message_id'] = []
    l_threads['length'] = []
    l_threads['subject'] = []
    l_threads['date'] = []
    l_threads['initiator_name'] = []
    l_threads['initiator_id'] = []
    for email in longest_threads:
        l_threads['message_id'].append(email.message_id)
        l_threads['length'].append(main_topics.lenThread(email.message_id))
        l_threads['subject'].append(email.subject)
        l_threads['date'].append(str(email.date))
        l_threads['initiator_name'].append(email.initiator_name)
        l_threads['initiator_id'].append(email.initiator_id)

    top_data['threads.'] = l_threads

    createJSON(top_data, opts.destdir+"/mls-top.json")
    

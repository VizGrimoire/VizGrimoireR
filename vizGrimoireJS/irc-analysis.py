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
# This file is a part of the vizGrimoire.R package
#
# Authors:
#     Alvaro del Castillo <acs@bitergia.com>
#
#
# Usage:
#     irc-analysis.py -d dbname
#
# For migrating to Python3: z = dict(list(x.items()) + list(y.items()))

from optparse import OptionParser
import sys
import pprint
import json

# R libraries called from python
from rpy2.robjects.packages import importr
import rpy2.rinterface as rinterface

isoweek = importr("ISOweek")
vizr = importr("vizgrimoire")

# To be shared from VizPy.py

def read_options():
    parser = OptionParser(usage="usage: %prog [options]",
                          version="%prog 0.1")
    parser.add_option("-d", "--database",
                      action="store",
                      dest="dbname",
                      help="Database where information is stored")
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
    parser.add_option("-g", "--granularity",
                      action="store",
                      dest="granularity",
                      default="months",
                      help="year,months,weeks granularity")
    parser.add_option("-o", "--destination",
                      action="store",
                      dest="destdir",
                      default="data/json",
                      help="Destination directory for JSON files")
    parser.add_option("-r", "--reports",
                      action="store",
                      dest="reports",
                      default="",
                      help="Reports to be generated (repositories, companies, countries, people)")
    parser.add_option("-s", "--start",
                      action="store",
                      dest="startdate",
                      default="1900-01-01",
                      help="Start date for the report")
    parser.add_option("-e", "--end",
                      action="store",
                      dest="enddate",
                      default="2100-01-01",
                      help="End date for the report")
    parser.add_option("-i", "--identities",
                      action="store",
                      dest="identities_db",
                      help="Database with unique identities and affiliations")

    (opts, args) = parser.parse_args()

    if len(args) != 0:
        parser.error("Wrong number of arguments")

    if not(opts.dbname and opts.dbuser and opts.identities_db):
        parser.error("--database --db-user and --identities are needed")
    return opts

# Convert a data frame to a python dictionary
def dataFrame2Dict(data):
    dict = {}

    # R start from 1 in data frames
    for i in range(1,len(data)+1):
        # Get the columns data frame
        col = data.rx(i)
        colname = col.names[0] 
        dict[colname] = [];
        for j in col:
            val = j[0]
            if val is rinterface.NA_Character: val = None
            dict[colname].append(val);
    return dict

def getPeriod(granularity):
    period = None
    if (granularity == 'years'):
        period = 'year'
        nperiod = 365
    elif (granularity == 'months'): 
        period = 'month'
        nperiod = 31
    elif (granularity == 'weeks'): 
        period = 'week'
        nperiod = 7
    elif (granularity == 'days'): 
        period = 'day'
        nperiod = 1
    else: 
        print("Incorrect period:",granularity)
        sys.exit(0)
    return period

def createJSON(data, filepath):
    jsonfile = open(filepath, 'w')
    # jsonfile.write(json.dumps(data, indent=4, separators=(',', ': ')))
    # jsonfile.write(json.dumps(data, indent=4, sort_keys=True))
    jsonfile.write(json.dumps(data, sort_keys=True))
    jsonfile.close()

if __name__ == '__main__':
    opts = read_options()

    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    period = getPeriod(opts.granularity)

    # multireport
    reports = opts.reports.split(",")

    # BOTS filtered
    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','']

    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    #
    # AGGREGATED DATA
    #
    agg_data = {}

    # Tendencies
    for i in [7,30,365]:
        period_data = dataFrame2Dict(vizr.GetIRCDiffSentDays(period, enddate, i))
        agg_data = dict(agg_data.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetIRCDiffSendersDays(period, enddate, opts.identities_db, i))
        agg_data = dict(agg_data.items() + period_data.items())

    # Global aggregated data
    static_data = vizr.GetStaticDataIRC(period, startdate, enddate, opts.identities_db)
    print(dataFrame2Dict(static_data))
    agg_data = dict(agg_data.items() + dataFrame2Dict(static_data).items())
    print(agg_data)

    # Time to write it to a json file
    createJSON (agg_data, opts.destdir+"/irc-static_py.json")

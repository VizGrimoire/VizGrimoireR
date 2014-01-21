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



import json
from optparse import OptionParser
import pprint
from rpy2.robjects.packages import importr
import rpy2.rinterface as rinterface
import sys

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

def valRtoPython(val):
    if val is rinterface.NA_Character: val = None
    # Check for .0 and convert to int
    elif isinstance(val, float):
        if (val % 1 == 0): val = int(val)
    return val

# Convert a data frame to a python dictionary
def dataFrame2Dict(data):
    dict = {}

    # R start from 1 in data frames
    for i in range(1,len(data)+1):
        # Get the columns data frame
        col = data.rx(i)
        colname = col.names[0]
        colvalues = col[0]
        dict[colname] = [];

        if (len(colvalues) == 1):
            dict[colname] = valRtoPython(colvalues[0])
        else:
            for j in colvalues: 
                dict[colname].append(valRtoPython(j))
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

def compareJSON(file1, file2):
    f1 = open(file1)
    f2 = open(file2)
    data1 = json.load(f1)
    data2 = json.load(f2)

    for name in data1:
        if data2.has_key(name) is False:
            print (name + " does not exists in " + file2)
            return False
        elif data1[name] != data2[name]:
            print (name + " diffent in dicts " + str(data1[name]) + " " + str(data2[name]))
            return False

    f1.close()
    f2.close()
    return True

def aggData(period, startdate, enddate, idb, destdir):
    #
    # AGGREGATED DATA
    #
    agg_data = {}

    # Tendencies
    for i in [7,30,365]:
        period_data = dataFrame2Dict(vizr.GetIRCDiffSentDays(period, enddate, i))
        agg_data = dict(agg_data.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetIRCDiffSendersDays(period, enddate, idb, i))
        agg_data = dict(agg_data.items() + period_data.items())

    # Global aggregated data
    static_data = vizr.GetStaticDataIRC(period, startdate, enddate, idb)
    agg_data = dict(agg_data.items() + dataFrame2Dict(static_data).items())

    createJSON (agg_data, destdir+"/irc-static_py.json")

    if compareJSON(destdir+"/irc-static.json", destdir+"/irc-static_py.json") is False:
        print("Wrong aggregated data generated from Python")
        sys.exit(1)

def completePeriodIds(ts_data, period, startdate, enddate):
    return ts_data

def tsData(period, startdate, enddate, idb, destdir):
    ts_data = {}
    ts_data = dataFrame2Dict(vizr.GetEvolDataIRC(period, startdate, enddate, idb))
    ts_data = completePeriodIds(ts_data, period, startdate, enddate)

    # evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
    # createJSON (evol_data, paste(destdir,"/irc-evolutionary.json", sep=''))
    createJSON (ts_data, destdir+"/irc-evolutionary_py.json")

    if compareJSON(destdir+"/irc-evolutionary.json", destdir+"/irc-evolutionary_py.json") is False:
        print("Wrong time series data generated from Python")
        sys.exit(1)


if __name__ == '__main__':
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # filtered bots
    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','']
        # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    aggData (period, startdate, enddate, opts.identities_db, opts.destdir)
    tsData (period, startdate, enddate, opts.identities_db, opts.destdir)
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

# Misc utils to be distributed in specific modules

import calendar
from datetime import datetime
from dateutil.relativedelta import relativedelta
import logging
import json
from optparse import OptionParser
import rpy2.rinterface as rinterface
from rpy2.robjects.vectors import StrVector
import sys



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
    elif (type(val) == StrVector):
        val2 = []
        for item in val: val2.append(item)
        val = val2
    return val

def completePeriodIdsMonths(ts_data, opts):
    # Always build a new dictionary completed
    new_ts_data = {}
    # opts = read_options()
    period = getPeriod(opts.granularity)
    start = datetime.strptime(opts.startdate, "%Y-%m-%d")
    end = datetime.strptime(opts.enddate, "%Y-%m-%d")

    # TODO: old format from R JSON. To be simplified
    new_ts_data['unixtime'] = []
    new_ts_data['date'] = []
    new_ts_data['id'] = []
    # new_ts_data['month'] = []
    data_vars = ts_data.keys()
    for key in (data_vars):
        new_ts_data[key] = []

    start_month = start.year*12 + start.month
    end_month = end.year*12 + end.month
    months = end_month - start_month

    for i in range(0, months+1):
        if (start_month+i in ts_data['month']) is False:
            # Add new time point with all vars to zero
            for key in (data_vars):
                new_ts_data[key].append(0)
            new_ts_data['month'].pop()
            new_ts_data['month'].append(start_month+i)
        else:
            # Add already existing data for the time point
            index = ts_data['month'].index(start_month+i)
            for key in (data_vars):
                new_ts_data[key].append(ts_data[key][index])

        current =  start + relativedelta(months=i)
        timestamp = calendar.timegm(current.timetuple())
        new_ts_data['unixtime'].append(unicode(timestamp))
        new_ts_data['id'].append(i)
        new_ts_data['date'].append(datetime.strftime(current, "%b %Y"))

    return new_ts_data


def completePeriodIds(ts_data):
    new_ts_data = ts_data
    opts = read_options()
    period = getPeriod(opts.granularity)

    if period == "month":
        new_ts_data = completePeriodIdsMonths(ts_data, opts)

    return new_ts_data



# Convert a R data frame to a python dictionary
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
        logging.error("Incorrect period:",granularity)
        sys.exit(1)
    return period

# Until we use VizPy we will create JSON python files with _py
def createJSON(data, filepath):
    filepath_py = filepath.split(".json")
    filepath_py = filepath_py[0]+"_py.json"
    jsonfile = open(filepath_py, 'w')
    jsonfile.write(json.dumps(data, sort_keys=True))
    jsonfile.close()

    if compareJSON(filepath, filepath_py) is False:
        logging.error("Wrong data generated from Python "+ filepath_py)
        sys.exit(1)

def compareJSON(file1, file2):
    check = True
    f1 = open(file1)
    f2 = open(file2)
    data1 = json.load(f1)
    data2 = json.load(f2)

    if len(data1) != len(data2):
        logging.warn(data1)
        logging.warn("is not")
        logging.warn(data2)
        check = False

    elif isinstance(data1, list):
        for i in range(0, len(data1)):
            if (data1[i] != data2[i]):
                logging.warn(data1)
                logging.warn("is not")
                logging.warn(data2)
                check = False
                break

    elif isinstance(data1, dict):
        for name in data1:
            if data2.has_key(name) is False:
                logging.warn (name + " does not exists in " + file2)
                check = False
                break
            elif data1[name] != data2[name]:
                logging.warn ("'"+name + "' different in dicts\n" + str(data1[name]) + "\n" + str(data2[name]))
                check = False
                break

    f1.close()
    f2.close()
    return check
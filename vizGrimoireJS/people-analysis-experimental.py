#!/usr/bin/env python
# -*- coding: utf-8 -*-

## Copyright (C) 2014 Bitergia
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## This file is a part of the vizGrimoire.R package
##
## Authors:
##   Luis Cañas Díaz <lcanas@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -d dbname < people-analysis.R

import logging
import sys

import time
#import GrimoireUtils
import GrimoireSQL
from GrimoireUtils import createJSON  # , completePeriodIds
#from GrimoireUtils import read_options, getPeriod
from SCM import GetPeopleListSCM, GetActivePeopleSCM, GetCommunityMembers
from MLS import GetActivePeopleMLS
from ITS import GetActivePeopleITS
from IRC import GetPeopleIRC
import People

from optparse import OptionParser
from ConfigParser import SafeConfigParser

# conf variables from file(see read_main_conf)
options = {}


def get_options():
    parser = OptionParser(usage='Usage: %prog [options]',
                          description='Executes the R scripts which analyze the information stored in the relational data bases and produce JSON files',
                          version='0.1')

    parser.add_option('-f', dest='config_file',
                      help='File path with the configuration for the R scripts',
                      default=None)
    parser.add_option('-g', '--debug', action='store_true', dest='debug',
                        help='Enable debug mode', default=False)

    (ops, args) = parser.parse_args()

    if ops.config_file is None:
        parser.print_help()
        print("Configuration file is required")
        sys.exit(1)
    return ops


def read_main_conf(config_file):
    #DO NOT MODIFY, duplicated function extracted from run-analysis.py
    parser = SafeConfigParser()
    fd = open(config_file, 'r')
    parser.readfp(fd)
    fd.close()

    sec = parser.sections()
    # we'll read "generic" for db information and "r" for start_date
    for s in sec:
        if not((s == "generic") or (s == "r")):
            continue
        options[s] = {}
        opti = parser.options(s)
        for o in opti:
            options[s][o] = parser.get(s, o)
    return options


def get_vars():
    v = {}
    v = options['generic']
    v.update(options['r'])
    # Fixed locations
    v['r_libs'] = '../../r-lib'
    v['python_libs'] = '../vizgrimoire'
    v['json_dir'] = '../../../json'

    # if end_date is not present or is empty we set up today's date
    if not ('end_date' in v):
        v['end_date'] = time.strftime('%Y-%m-%d')

    # FIXME this should be included in the main log file
    v['log_file'] = 'run-analysis.log'
    return v


def active_members(people_static):
    GrimoireSQL.SetDBChannel(database=env['db_cvsanaly'],
                             user=dbuser, password=dbpassword)

    apersons_scm_7 = GetActivePeopleSCM(7, enddate)
    apersons_scm_30 = GetActivePeopleSCM(30, enddate)
    apersons_scm_180 = GetActivePeopleSCM(180, enddate)
    apersons_scm_365 = GetActivePeopleSCM(365, enddate)

    GrimoireSQL.SetDBChannel(database=env['db_bicho'],
                             user=dbuser, password=dbpassword)
    apersons_its_7 = GetActivePeopleITS(7, enddate)
    apersons_its_30 = GetActivePeopleITS(30, enddate)
    apersons_its_180 = GetActivePeopleITS(180, enddate)
    apersons_its_365 = GetActivePeopleITS(365, enddate)

    GrimoireSQL.SetDBChannel(database=env['db_mlstats'],
                             user=dbuser, password=dbpassword)
    apersons_mls_7 = GetActivePeopleMLS(7, enddate)
    apersons_mls_30 = GetActivePeopleMLS(30, enddate)
    apersons_mls_180 = GetActivePeopleMLS(180, enddate)
    apersons_mls_365 = GetActivePeopleMLS(365, enddate)

    active_members_7 = []
    active_members_7 = apersons_scm_7 + apersons_its_7 + apersons_mls_7
    active_members_7 = list(set(active_members_7))
    n_active_members_7 = len(active_members_7)
    print("n_active_members_7 = %s" % (n_active_members_7))

    active_members_30 = []
    active_members_30 = apersons_scm_30 + apersons_its_30 + apersons_mls_30
    active_members_30 = list(set(active_members_30))
    n_active_members_30 = len(active_members_30)
    print("n_active_members_30 = %s" % (n_active_members_30))

    active_members_180 = []
    active_members_180 = apersons_scm_180 + apersons_its_180 + apersons_mls_180
    active_members_180 = list(set(active_members_180))
    n_active_members_180 = len(active_members_180)
    print("n_active_members_180 = %s" % (n_active_members_180))

    active_members_365 = []
    active_members_365 = apersons_scm_365 + apersons_its_365 + apersons_mls_365
    active_members_365 = list(set(active_members_365))
    n_active_members_365 = len(active_members_365)
    print("n_active_members_365 = %s" % (n_active_members_365))

    people_static["active_members_365"] = n_active_members_365
    people_static["active_members_180"] = n_active_members_180
    people_static["active_members_30"] = n_active_members_30
    people_static["active_members_7"] = n_active_members_7
    return(people_static)


def people_list():
    GrimoireSQL.SetDBChannel(database=env['db_cvsanaly'],
                             user=dbuser, password=dbpassword)
    people_data = {}
    people = GetPeopleListSCM(startdate, enddate)
    people = people['pid']
    limit = 100
    if (len(people) < limit):
        limit = len(people)  # end
    people = people[0:limit]
    for upeople_id in people:
        people_data[upeople_id] = People.GetPersonIdentifiers(upeople_id)
    return(people_data)


def community_members(people_static):
    GrimoireSQL.SetDBChannel(database=env['db_cvsanaly'],
                             user=dbuser, password=dbpassword)
    members_ids = GetCommunityMembers()
    irc_members_ids = GetPeopleIRC()
    members_ids = list(set(members_ids) - set(irc_members_ids))
    n_members = len(members_ids)    
    people_static["members"] = n_members
    return(people_static)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s')
    logging.info("Starting People EXPERIMENTAL data source analysis")
    opt = get_options()
    read_main_conf(opt.config_file)
    env = get_vars()
    startdate = "'"+env['end_date']+"'"
    enddate = "'"+env['end_date']+"'"
    dbuser = env['db_user']
    dbpassword = env['db_password']
    destdir = options['r']['json_dir']

    people_data = people_list()
    print(people_data)
    createJSON(people_data, destdir+"/people.json")

    #FIXME check data sources with a variable from automator conf
    people_static = {}
    people_static = active_members(people_static)
    people_static = community_members(people_static)
    print(people_static)
    createJSON(people_static, destdir+"/people-static.json")

    logging.info("People data source analysis OK")

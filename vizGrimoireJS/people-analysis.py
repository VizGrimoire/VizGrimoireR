#!/usr/bin/env python

## Copyright (C) 2012, 2013 Bitergia
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
##   Alvaro del Castillo <acs@bitergia.com>
##
##

import logging
import sys
from ConfigParser import SafeConfigParser

import GrimoireUtils, GrimoireSQL
from GrimoireUtils import createJSON, completePeriodIds
from GrimoireUtils import read_options, getPeriod
from SCM import GetPeopleListSCM
import SCM, ITS, MLS, SCR, Mediawiki, IRC
import People

def read_main_conf(config_file):
    options = {}
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


# Top people for all data sources. Wikimedia specific
def topPeople(startdate, enddate, idb, bots):
    npeople = "10000" # max limit, all people included
    tops = {}
    all_top = {}
    all_top_all_ds = {}
    db = automator['generic']['db_gerrit']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    tops["scr"] = SCR.GetTopOpenersSCR(0, startdate, enddate, idb, bots, npeople)
    db = automator['generic']['db_mlstats']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    tops["mls"] = MLS.top_senders(0, startdate, enddate, idb, bots, npeople)
    db = automator['generic']['db_bicho']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    # Fixed for bugzilla, what Wikimedia uses
    closed_condition = "(new_value='RESOLVED' OR new_value='CLOSED' OR new_value='Lowest')"
    # TODO: include in "-Bot" company all the bots
    tops["its"] = ITS.GetTopOpeners(0, startdate, enddate, idb, ["-Bot"], closed_condition, npeople)
    db = automator['generic']['db_irc']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    tops["irc"] = IRC.GetTopSendersIRC(0, startdate, enddate, idb, bots, npeople)
    db = automator['generic']['db_mediawiki']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    tops["mediawiki"] = Mediawiki.GetTopAuthorsMediaWiki(0, startdate, enddate, idb, bots, npeople)
    # TODO: include in "-Bot" company all the bots
    db = automator['generic']['db_cvsanaly']
    GrimoireSQL.SetDBChannel (database=db, user=opts.dbuser, password=opts.dbpassword)
    tops["scm"] = SCM.top_people(0, startdate, enddate, "author" , ["-Bot"] , npeople)

    # Build the consolidated top list using all data sources data
    # Only people in all data sources is used
    for ds in tops:
        pos = 1;
        for id in tops[ds]['id']:
            if id not in all_top: all_top[id] = []
            all_top[id].append({"ds":ds,"pos":pos})
            pos += 1

    for id in all_top:
        if len(all_top[id])>5: all_top_all_ds[id] = all_top[id]

    createJSON(all_top_all_ds, opts.destdir+"/all_top.json")

def createPeopleIdentifiers(startdate, enddate):
    people_data = {}
    people = GetPeopleListSCM(startdate, enddate)
    people = people['pid']
    limit = 550
    if (len(people)<limit): limit = len(people);
    people = people[0:limit]

    for upeople_id in people:
        people_data[upeople_id] = People.GetPersonIdentifiers(upeople_id)
    createJSON(people_data, opts.destdir+"/people.json")


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting People data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"


    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','','Translation updater bot','jenkins-bot','L10n-bot']

    # Working at the same time with VizR and VizPy yet
    # vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    createPeopleIdentifiers(startdate, enddate)

    if opts.config_file:
        automator = read_main_conf(opts.config_file)
        topPeople(startdate, enddate, opts.identities_db, bots)

    logging.info("People data source analysis OK")

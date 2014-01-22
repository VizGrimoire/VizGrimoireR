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
#     PYTHONPATH=../vizgrimoire LANG= R_LIBS=../../r-lib ./irc-analysis.py 
#                                                -d acs_irc_automatortest_2388_2 -u root 
#                                                -i acs_cvsanaly_automatortest_2388 
#                                                -s 2010-01-01 -e 2014-01-20 
#                                                -o ../../../json -r people,repositories
#
# For migrating to Python3: z = dict(list(x.items()) + list(y.items()))



import logging
from rpy2.robjects.packages import importr
import sys

import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds
from GrimoireUtils import valRtoPython, read_options, getPeriod
import IRC

isoweek = importr("ISOweek")
vizr = importr("vizgrimoire")


def aggData(period, startdate, enddate, idb, destdir):
    agg_data = {}

    # Tendencies
    for i in [7,30,365]:
        # period_data = dataFrame2Dict(vizr.GetIRCDiffSentDays(period, enddate, i))
        period_data = IRC.GetIRCDiffSentDays(period, enddate, i)
        agg_data = dict(agg_data.items() + period_data.items())
        # period_data = dataFrame2Dict(vizr.GetIRCDiffSendersDays(period, enddate, idb, i))
        period_data = IRC.GetIRCDiffSendersDays(period, enddate, idb, i)
        agg_data = dict(agg_data.items() + period_data.items())

    # Global aggregated data
    # static_data = vizr.GetStaticDataIRC(period, startdate, enddate, idb)
    static_data = IRC.GetStaticDataIRC(period, startdate, enddate, idb)
    agg_data = dict(agg_data.items() + static_data.items())

    createJSON (agg_data, destdir+"/irc-static.json")

def tsData(period, startdate, enddate, idb, destdir):
    ts_data = {}
    # ts_data = dataFrame2Dict(vizr.GetEvolDataIRC(period, startdate, enddate, idb))
    ts_data = IRC.GetEvolDataIRC(period, startdate, enddate, idb)
    ts_data = completePeriodIds(ts_data)
    createJSON (ts_data, destdir+"/irc-evolutionary.json")

def peopleData(period, startdate, enddate, idb, destdir):
    # people_data = dataFrame2Dict(vizr.GetListPeopleIRC(startdate, enddate))
    people_data = IRC.GetListPeopleIRC(startdate, enddate)
    people = people_data['id']
    limit = 30
    if (len(people)<limit): limit = len(people);
    people = people[0:limit]
    people_file = destdir+"/irc-people.json"
    createJSON(people, people_file)

    for upeople_id in people:
        # evol = dataFrame2Dict(vizr.GetEvolPeopleIRC(upeople_id, period, startdate, enddate))
        evol = IRC.GetEvolPeopleIRC(upeople_id, period, startdate, enddate)
        evol = completePeriodIds(evol)
        person_file = destdir+"/people-"+str(upeople_id)+"-irc-evolutionary.json"
        createJSON(evol, person_file)

        person_file = destdir+"/people-"+str(upeople_id)+"-irc-static.json"
        # aggdata = dataFrame2Dict(vizr.GetStaticPeopleIRC(upeople_id, startdate, enddate))
        aggdata = IRC.GetStaticPeopleIRC(upeople_id, startdate, enddate)
        createJSON(aggdata, person_file)

# TODO: pretty similar to peopleData. Unify?
def reposData(period, startdate, enddate, idb, destdir):
    # repos_data = dataFrame2Dict(vizr.GetReposNameIRC())
    repos = valRtoPython(vizr.GetReposNameIRC())
    repos_file = destdir+"/irc-repos.json"
    createJSON(repos, repos_file)

    for repo in repos:
        # evol = vizr.GetRepoEvolSentSendersIRC(repo, period, startdate, enddate)
        evol = IRC.GetRepoEvolSentSendersIRC(repo, period, startdate, enddate)
        # evol = completePeriodIds(dataFrame2Dict(evol))
        evol = completePeriodIds(evol)
        repo_file = destdir+"/"+repo+"-irc-rep-evolutionary.json"
        createJSON(evol, repo_file)

        repo_file = destdir+"/"+repo+"-irc-rep-static.json"
        aggdata = vizr.GetRepoStaticSentSendersIRC(repo, startdate, enddate)
        createJSON(dataFrame2Dict(aggdata), repo_file)

def topData(period, startdate, enddate, idb, destdir, bots):
    top_senders = {}
    top_senders['senders.'] = \
        dataFrame2Dict(vizr.GetTopSendersIRC(0, startdate, enddate, idb, bots))
    top_senders['senders.last year'] = \
        dataFrame2Dict(vizr.GetTopSendersIRC(365, startdate, enddate, idb, bots))
    top_senders['senders.last month'] = \
        dataFrame2Dict(vizr.GetTopSendersIRC(31, startdate, enddate, idb, bots))
    top_file = destdir+"/irc-top.json"
    createJSON (top_senders, top_file)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting IRC data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # filtered bots
    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','']
        # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    # Working at the same time with VizR and VizPy yet
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    aggData (period, startdate, enddate, opts.identities_db, opts.destdir)
    tsData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir)
    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)

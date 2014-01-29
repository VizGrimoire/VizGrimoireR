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
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo San Felix <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##


import logging
from rpy2.robjects.packages import importr
import sys

isoweek = importr("ISOweek")
vizr = importr("vizgrimoire")

import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds
from GrimoireUtils import valRtoPython, read_options, getPeriod
import Mediawiki

def aggData(period, startdate, enddate, identities_db, destdir):
    # Tendencies
    agg = {}
    for i in [7,30,365]:
        data = vizr.GetMediaWikiDiffReviewsDays(period, enddate, i)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = vizr.GetMediaWikiDiffAuthorsDays(period, enddate, identities_db, i)
        agg = dict(agg.items() + dataFrame2Dict(data).items())

    data = vizr.GetStaticDataMediaWiki(period, startdate, enddate, identities_db)
    agg = dict(agg.items() + dataFrame2Dict(data).items())

    createJSON (agg, destdir+"/mediawiki-static.json")

def tsData(period, startdate, enddate, identities_db, destdir, granularity, conf):
    evol_data = vizr.GetEvolDataMediaWiki(period, startdate, enddate, identities_db)
    evol_data = completePeriodIds(dataFrame2Dict(evol_data))
    createJSON (evol_data, destdir+"/mediawiki-evolutionary.json")

def peopleData(period, startdate, enddate, identities_db, destdir):
    people = dataFrame2Dict(vizr.GetListPeopleMediaWiki(startdate, enddate))
    people = people['id']
    limit = 30
    if (len(people)<limit): limit = len(people);
    people = people[0:limit]
    createJSON(people, destdir+"/mediawiki-people.json")

    for upeople_id in people:
        evol = vizr.GetEvolPeopleMediaWiki(upeople_id, period, startdate, enddate)
        evol = completePeriodIds(dataFrame2Dict(evol))
        createJSON(evol, destdir+"/people-"+str(upeople_id)+"-mediawiki-evolutionary.json")

        static = vizr.GetStaticPeopleMediaWiki(upeople_id, startdate, enddate)
        createJSON(dataFrame2Dict(static), destdir+"/people-"+str(upeople_id)+"-mediawiki-static.json")

def reposData(period, startdate, enddate, identities_db, destdir, conf):
    pass

def companiesData(period, startdate, enddate, identities_db, destdir):
    pass

def countriesData(period, startdate, enddate, identities_db, destdir):
    pass

def topData(period, startdate, enddate, identities_db, destdir, bots):
    top_authors = {}
    top_authors['authors.'] = dataFrame2Dict(vizr.GetTopAuthorsMediaWiki(0, startdate, enddate, identities_db, bots))
    top_authors['authors.last year']= dataFrame2Dict(vizr.GetTopAuthorsMediaWiki(365, startdate, enddate, identities_db, bots))
    top_authors['authors.last month']= dataFrame2Dict(vizr.GetTopAuthorsMediaWiki(31, startdate, enddate, identities_db, bots))
    createJSON (top_authors, destdir+"/mediawiki-top.json")

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting MLS data source analysis")
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
    # GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)
    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)

    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)
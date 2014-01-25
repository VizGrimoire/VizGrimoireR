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
#     PYTHONPATH=../vizgrimoire LANG= R_LIBS=../../r-lib ./scr-analysis.py 
#                                                -d acs_irc_automatortest_2388_2 -u root 
#                                                -i acs_cvsanaly_automatortest_2388 
#                                                -s 2010-01-01 -e 2014-01-20 
#                                                -o ../../../json -r people,repositories
#

import logging
from rpy2.robjects.packages import importr
import sys

isoweek = importr("ISOweek")
vizr = importr("vizgrimoire")

import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds
from GrimoireUtils import valRtoPython, read_options, getPeriod
import IRC

def aggData(period, startdate, enddate, idb, destdir):
    data = vizr.StaticReviewsSubmitted(period, startdate, enddate)
    agg = dataFrame2Dict(data)
    data = vizr.StaticReviewsOpened(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsNew(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsInProgress(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsClosed(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsMerged(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsAbandoned(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticReviewsPending(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticPatchesVerified(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticPatchesApproved(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticPatchesCodeReview(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticPatchesSent(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticWaiting4Reviewer(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    data = vizr.StaticWaiting4Submitter(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    # print(agg)
    #Reviewers info
    data = vizr.StaticReviewers(period, startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())
    # Time to Review info
    data = vizr.StaticTimeToReviewSCR(startdate, enddate)
    agg = dict(agg.items() + dataFrame2Dict(data).items())

    # Tendencies
    for i in [7,30,365]:
        period_data = dataFrame2Dict(vizr.GetSCRDiffSubmittedDays(period, enddate, i, idb))
        agg = dict(agg.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetSCRDiffMergedDays(period, enddate, i, idb))
        agg = dict(agg.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetSCRDiffPendingDays(period, enddate, i, idb))
        agg = dict(agg.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetSCRDiffAbandonedDays(period, enddate, i, idb))
        agg = dict(agg.items() + period_data.items())

    # Create JSON
    createJSON(agg, destdir+"/scr-static.json")

def tsData(period, startdate, enddate, idb, destdir, granularity, conf):
    evol = {}
    data = vizr.EvolReviewsSubmitted(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsOpened(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsNew(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsNewChanges(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsInProgress(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsClosed(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsMerged(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsMergedChanges(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsAbandoned(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolReviewsAbandonedChanges(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    # TODO: We can not use this R API because Python conf can't be pass to R  
    # data = dataFrame2Dict(vizr.EvolReviewsPendingChanges(period, startdate, enddate, conf))
    #Patches info
    data = vizr.EvolPatchesVerified(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolPatchesApproved(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolPatchesCodeReview(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolPatchesSent(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    #Waiting for actions info
    data = vizr.EvolWaiting4Reviewer(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = vizr.EvolWaiting4Submitter(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    #Reviewers info
    data = vizr.EvolReviewers(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    # Time to Review info
    data = vizr.EvolTimeToReviewSCR (period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    # Create JSON
    createJSON(evol, destdir+"/scr-evolutionary.json")

def peopleData(period, startdate, enddate, idb, destdir):
    people = dataFrame2Dict(vizr.GetPeopleListSCR(startdate, enddate))
    people = people["id"]
    limit = 60
    if (len(people)<limit): limit = len(people);
    # The order of the list item change so we can not check it
    createJSON(people, destdir+"/scr-people.json", False)

    for upeople_id in people:
        evol = vizr.GetPeopleEvolSCR(upeople_id, period, startdate, enddate)
        evol = completePeriodIds(dataFrame2Dict(evol))
        createJSON(evol, destdir+"/people-"+str(upeople_id)+"-scr-evolutionary.json")

        agg = dataFrame2Dict(vizr.GetPeopleStaticSCR(upeople_id, startdate, enddate))
        createJSON(agg, destdir+"/people-"+str(upeople_id)+"-scr-static.json")

def reposData(period, startdate, enddate, idb, destdir):
    repos  = dataFrame2Dict(vizr.GetReposSCRName(startdate, enddate))
    repos = repos["name"]
    repos_files = [repo.replace('/', '_') for repo in repos]
    createJSON(repos_files, destdir+"/scr-repos.json")

    # missing information from the rest of type of reviews, patches and
    # number of patches waiting for reviewer and submitter 
    for repo in repos:
        repo_file = repo.replace("/","_")
        type_analysis = ['repository', repo]

        evol = {}
        data = vizr.EvolReviewsSubmitted(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = vizr.EvolReviewsMerged(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = vizr.EvolReviewsAbandoned(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        # data = vizr.EvolReviewsPendingChanges(period, startdate, enddate, conf, type_analysis)
        # evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = vizr.EvolTimeToReviewSCR(period, startdate, enddate, idb, type_analysis)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        createJSON(evol, destdir+ "/"+repo_file+"-scr-rep-evolutionary.json")

        # Static
        agg = {}
        data = vizr.StaticReviewsSubmitted(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = vizr.StaticReviewsMerged(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = vizr.StaticReviewsAbandoned(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = vizr.StaticReviewsPending(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = vizr.StaticTimeToReviewSCR(startdate, enddate, idb, type_analysis)
        agg = dict(agg.items() + dataFrame2Dict(data).items())
        createJSON(agg, destdir + "/"+repo_file + "-scr-rep-static.json")

def companiesData(period, startdate, enddate, idb, destdir):
    pass

def countriesData(period, startdate, enddate, idb, destdir):
    pass

def topData(period, startdate, enddate, idb, destdir, bots):
    top_reviewers = {}
    top_reviewers['reviewers'] = dataFrame2Dict(vizr.GetTopReviewersSCR(0, startdate, enddate, idb, bots))
    top_reviewers['reviewers.last year']= dataFrame2Dict(vizr.GetTopReviewersSCR(365, startdate, enddate, idb, bots))
    top_reviewers['reviewers.last month']= dataFrame2Dict(vizr.GetTopReviewersSCR(31, startdate, enddate, idb, bots))

    # Top openers
    top_openers = {}
    top_openers['openers.']=dataFrame2Dict(vizr.GetTopOpenersSCR(0, startdate, enddate,idb, bots))
    top_openers['openers.last year']=dataFrame2Dict(vizr.GetTopOpenersSCR(365, startdate, enddate,idb, bots))
    top_openers['openers.last_month']=dataFrame2Dict(vizr.GetTopOpenersSCR(31, startdate, enddate,idb, bots))

    # Top mergers
    top_mergers = {}
    top_mergers['mergers.last year']=dataFrame2Dict(vizr.GetTopMergersSCR(365, startdate, enddate,idb, bots))
    top_mergers['mergers.']=dataFrame2Dict(vizr.GetTopMergersSCR(0, startdate, enddate,idb, bots))
    top_mergers['mergers.last_month']=dataFrame2Dict(vizr.GetTopMergersSCR(31, startdate, enddate,idb, bots))

    # The order of the list item change so we can not check it
    createJSON (dict(top_reviewers.items() +  top_openers.items() + top_mergers.items()), destdir+"/scr-top.json",False)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting SCR data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # filtered bots

    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','','Translation updater bot','jenkins-bot']
    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    # Working at the same time with VizR and VizPy yet
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)

    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)

    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)


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

from datetime import datetime
from dateutil.relativedelta import relativedelta
import logging
# from rpy2.robjects.packages import importr
import sys
from Wikimedia import GetCompaniesQuartersSCR, GetPeopleQuartersSCR

# isoweek = importr("ISOweek")
# vizr = importr("vizgrimoire")

import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds
from GrimoireUtils import valRtoPython, read_options, getPeriod
import SCR

def aggData(period, startdate, enddate, idb, destdir):
    # Wikimedia data ok after '2013-04-30' for changes based metrics
    startok = "'2013-04-30'"

    # data = vizr.StaticReviewsSubmitted(period, startdate, enddate)
    # agg = dataFrame2Dict(data)
    agg = SCR.StaticReviewsSubmitted(period, startdate, enddate)
    data = SCR.StaticReviewsOpened(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsNew(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsInProgress(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsClosed(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsMerged(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsAbandoned(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticReviewsPending(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticPatchesVerified(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticPatchesApproved(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticPatchesCodeReview(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticPatchesSent(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticWaiting4Reviewer(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    data = SCR.StaticWaiting4Submitter(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    # print(agg)
    #Reviewers info
    data = SCR.StaticReviewers(period, startdate, enddate)
    agg = dict(agg.items() + data.items())
    # Time to Review info
    data = SCR.StaticTimeToReviewSCR(startok, enddate)
    data['review_time_days_avg'] = float(data['review_time_days_avg'])
    agg = dict(agg.items() + data.items())

    # Tendencies
    for i in [7,30,365]:
        period_data = SCR.GetSCRDiffSubmittedDays(period, enddate, i, idb)
        agg = dict(agg.items() + period_data.items())
        period_data = SCR.GetSCRDiffMergedDays(period, enddate, i, idb)
        agg = dict(agg.items() + period_data.items())
        period_data = SCR.GetSCRDiffPendingDays(period, enddate, i, idb)
        agg = dict(agg.items() + period_data.items())
        period_data = SCR.GetSCRDiffAbandonedDays(period, enddate, i, idb)
        agg = dict(agg.items() + period_data.items())

    # Create JSON
    createJSON(agg, destdir+"/scr-static.json")

def tsData(period, startdate, enddate, idb, destdir, granularity, conf):
    # Wikimedia data ok after '2013-04-30' for changes based metrics
    startok = "'2013-04-30'"

    evol = {}
    # data = vizr.EvolReviewsSubmitted(period, startdate, enddate)
    # evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = SCR.EvolReviewsSubmitted(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsOpened(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsNew(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsNewChanges(period, startok, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    # data = SCR.EvolReviewsInProgress(period, startdate, enddate)
    # evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsClosed(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsMerged(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsMergedChanges(period, startok, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsAbandoned(period, startok, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolReviewsAbandonedChanges(period, startok, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    # TODO: We can not use this R API because Python conf can't be pass to R  
    # data = dataFrame2Dict(vizr.EvolReviewsPendingChanges(period, startdate, enddate, conf))
    data = SCR.EvolReviewsPendingChanges(period, startdate, enddate, conf, [])
    evol = dict(evol.items() + completePeriodIds(data).items())
    #Patches info
    data = SCR.EvolPatchesVerified(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    # data = SCR.EvolPatchesApproved(period, startdate, enddate)
    # evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolPatchesCodeReview(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolPatchesSent(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    #Waiting for actions info
    data = SCR.EvolWaiting4Reviewer(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    data = SCR.EvolWaiting4Submitter(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    #Reviewers info
    data = SCR.EvolReviewers(period, startdate, enddate)
    evol = dict(evol.items() + completePeriodIds(data).items())
    # Time to Review info
    data = SCR.EvolTimeToReviewSCR (period, startok, enddate)
    for i in range(0,len(data['review_time_days_avg'])):
        val = data['review_time_days_avg'][i] 
        data['review_time_days_avg'][i] = float(val)
        if (val == 0): data['review_time_days_avg'][i] = 0
    evol = dict(evol.items() + completePeriodIds(data).items())
    # Create JSON
    createJSON(evol, destdir+"/scr-evolutionary.json")

# Unify top format
def safeTopIds(top_data_period):
    if not isinstance(top_data_period['id'], (list)):
        for name in top_data_period:
            top_data_period[name] = [top_data_period[name]]
    return top_data_period['id']

def peopleData(period, startdate, enddate, idb, destdir, top_data):
    top = safeTopIds(top_data['reviewers'])
    top += safeTopIds(top_data['reviewers.last year'])
    top += safeTopIds(top_data['reviewers.last month'])
    top += safeTopIds(top_data['openers.'])
    top += safeTopIds(top_data['openers.last year'])
    top += safeTopIds(top_data['openers.last_month'])
    top += safeTopIds(top_data['mergers.'])
    top += safeTopIds(top_data['mergers.last year'])
    top += safeTopIds(top_data['mergers.last_month'])
    # remove duplicates
    people = list(set(top))
    print(people)
    # the order is not the same than in R json 
    createJSON(people, destdir+"/scr-people.json", False)

    for upeople_id in people:
        # evol = vizr.GetPeopleEvolSCR(upeople_id, period, startdate, enddate)
        # evol = completePeriodIds(dataFrame2Dict(evol))
        evol = SCR.GetPeopleEvolSCR(upeople_id, period, startdate, enddate)
        evol = completePeriodIds(evol)
        createJSON(evol, destdir+"/people-"+str(upeople_id)+"-scr-evolutionary.json")

        # agg = dataFrame2Dict(vizr.GetPeopleStaticSCR(upeople_id, startdate, enddate))
        agg = SCR.GetPeopleStaticSCR(upeople_id, startdate, enddate)
        createJSON(agg, destdir+"/people-"+str(upeople_id)+"-scr-static.json")

def reposData(period, startdate, enddate, idb, destdir, conf):
    # repos  = dataFrame2Dict(vizr.GetReposSCRName(startdate, enddate))
    repos  = SCR.GetReposSCRName(startdate, enddate)
    repos = repos["name"]
    repos_files = [repo.replace('/', '_') for repo in repos]
    createJSON(repos_files, destdir+"/scr-repos.json")

    # missing information from the rest of type of reviews, patches and
    # number of patches waiting for reviewer and submitter 
    for repo in repos:
        repo_file = repo.replace("/","_")
        logging.info("Repo: " + repo_file)
        type_analysis = ['repository', repo]

        evol = {}
        # data = vizr.EvolReviewsSubmitted(period, startdate, enddate, type_analysis)
        data = SCR.EvolReviewsSubmitted(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsMerged(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsAbandoned(period, startdate, enddate, type_analysis)
        evol = dict(evol.items() + completePeriodIds(data).items())
        # data = vizr.EvolReviewsPendingChanges(period, startdate, enddate, conf, type_analysis)
        # evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = SCR.EvolReviewsPendingChanges(period, startdate, enddate, conf, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolTimeToReviewSCR(period, startdate, enddate, idb, type_analysis)
        for i in range(0,len(data['review_time_days_avg'])):
            val = data['review_time_days_avg'][i] 
            data['review_time_days_avg'][i] = float(val)
            if (val == 0): data['review_time_days_avg'][i] = 0
        evol = dict(evol.items() + completePeriodIds(data).items())
        # For some reason this repos include merged_changes - 235 repos total
        if (repo_file == "gerrit.wikimedia.org_mediawiki_extensions_CodeReview" or
            repo_file == "gerrit.wikimedia.org_analytics_geowiki" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_DataTypes" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_NewUserMessage" or
            repo_file == "gerrit.wikimedia.org_pywikibot_sf-export" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_CharInsert" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_StrategyWiki" or
            repo_file == "gerrit.wikimedia.org_analytics_kraken" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_UnicodeConverter" or
            repo_file == "gerrit.wikimedia.org_operations_puppet_jmxtrans" or
            repo_file == "gerrit.wikimedia.org_integration_testswarm" or
            repo_file == "gerrit.wikimedia.org_integration_testswarm" or
            repo_file == "gerrit.wikimedia.org_openstack-wikistatus" or
            repo_file == "gerrit.wikimedia.org_wikimedia_communications_WP-Victor" or
            repo_file == "gerrit.wikimedia.org_wikimedia_bugzilla_wikibugs" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_fluoride" or
            repo_file == "gerrit.wikimedia.org_mediawiki_rcsub" or
            repo_file == "gerrit.wikimedia.org_integration_doc" or
            repo_file == "gerrit.wikimedia.org_analytics_udplog" or
            repo_file == "gerrit.wikimedia.org_mediawiki_extensions_ActiveAbstract" or
            repo_file == "gerrit.wikimedia.org_integration_grunt-contrib-wikimedia" or
            repo_file == "gerrit.wikimedia.org_analytics_global-dev_dashboard" or
            repo_file == "gerrit.wikimedia.org_wikimedia_communications_WMBlog" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_commonshelper2" or
            repo_file == "gerrit.wikimedia.org_wikimedia_bugzilla_triagescripts" or
            repo_file == "gerrit.wikimedia.org_integration_junitdiff" or
            repo_file == "gerrit.wikimedia.org_wikimedia_fundraising_twig" or
            repo_file == "gerrit.wikimedia.org_analytics_blog" or
            repo_file == "gerrit.wikimedia.org_operations_software_otrs" or
            repo_file == "gerrit.wikimedia.org_wikimedia_fundraising_stomp" or
            repo_file == "gerrit.wikimedia.org_operations_dumps_test" or
            repo_file == "gerrit.wikimedia.org_integration_consistency" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_dippybird" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_upload_PhotoUpload" or
            repo_file == "gerrit.wikimedia.org_mediawiki_php_NativePreprocessor" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_bundles" or
            repo_file == "gerrit.wikimedia.org_mediawiki_tools_Cite4Wiki" or
            repo_file == "gerrit.wikimedia.org_operations_software_varnish_vhtcpd"):
            createJSON(evol, destdir+ "/"+repo_file+"-scr-rep-evolutionary.json", False)
        else:
            createJSON(evol, destdir+ "/"+repo_file+"-scr-rep-evolutionary.json")

        # Static
        agg = {}
        data = SCR.StaticReviewsSubmitted(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsMerged(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsAbandoned(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsPending(period, startdate, enddate, type_analysis)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticTimeToReviewSCR(startdate, enddate, idb, type_analysis)
        val = data['review_time_days_avg']
        if (not val or val == 0): data['review_time_days_avg'] = 0
        else: data['review_time_days_avg'] = float(val)
        agg = dict(agg.items() + data.items())
        createJSON(agg, destdir + "/"+repo_file + "-scr-rep-static.json")

def companiesData(period, startdate, enddate, idb, destdir):
    # companies  = dataFrame2Dict(vizr.GetCompaniesSCRName(startdate, enddate, idb))
    companies  = SCR.GetCompaniesSCRName(startdate, enddate, idb)
    companies = companies['name']
    companies_files = [company.replace('/', '_') for company in companies]
    createJSON(companies_files, destdir+"/scr-companies.json")

    # missing information from the rest of type of reviews, patches and
    # number of patches waiting for reviewer and submitter 
    for company in companies:
        company_file = company.replace("/","_")
        type_analysis = ['company', company]
        # Evol
        evol = {}
        # data = vizr.EvolReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
        # evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = SCR.EvolReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsMerged(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsAbandoned(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        createJSON(evol, destdir+ "/"+company_file+"-scr-com-evolutionary.json")
        # Static
        agg = {}
#        data = vizr.StaticReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
#        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = SCR.StaticReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsMerged(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsAbandoned(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        createJSON(agg, destdir+"/"+company_file+"-scr-com-static.json")


def countriesData(period, startdate, enddate, idb, destdir):
    # countries  = dataFrame2Dict(vizr.GetCountriesSCRName(startdate, enddate, idb))
    countries  = SCR.GetCountriesSCRName(startdate, enddate, idb)
    countries = countries['name']
    countries_files = [country.replace('/', '_') for country in countries]
    createJSON(countries_files, destdir+"/scr-countries.json")

    # missing information from the rest of type of reviews, patches and
    # number of patches waiting for reviewer and submitter 
    for country in countries:
        country_file = country.replace("/","_")
        type_analysis = ['country', country]
        # Evol
        evol = {}
#        data = vizr.EvolReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
#        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
        data = SCR.EvolReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsMerged(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        data = SCR.EvolReviewsAbandoned(period, startdate, enddate, type_analysis, idb)
        evol = dict(evol.items() + completePeriodIds(data).items())
        # TODO: when empty abandoned does not appeat at all in R JSON 
        createJSON(evol, destdir+ "/"+country_file+"-scr-cou-evolutionary.json",False)
        # Static
        agg = {}
#        data = vizr.StaticReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
#        agg = dict(agg.items() + dataFrame2Dict(data).items())
        data = SCR.StaticReviewsSubmitted(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsMerged(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        data = SCR.StaticReviewsAbandoned(period, startdate, enddate, type_analysis, idb)
        agg = dict(agg.items() + data.items())
        createJSON(agg, destdir+"/"+country_file+"-scr-cou-static.json")

def topData(period, startdate, enddate, idb, destdir, bots, npeople):
    top_reviewers = {}
#    top_reviewers['reviewers'] = dataFrame2Dict(vizr.GetTopReviewersSCR(0, startdate, enddate, idb, bots))
    top_reviewers['reviewers'] = SCR.GetTopReviewersSCR(0, startdate, enddate, idb, bots, npeople)
    top_reviewers['reviewers.last year']= SCR.GetTopReviewersSCR(365, startdate, enddate, idb, bots, npeople)
    top_reviewers['reviewers.last month']= SCR.GetTopReviewersSCR(31, startdate, enddate, idb, bots, npeople)

    # Top openers
    top_openers = {}
    top_openers['openers.']=SCR.GetTopOpenersSCR(0, startdate, enddate,idb, bots, npeople)
    top_openers['openers.last year']=SCR.GetTopOpenersSCR(365, startdate, enddate,idb, bots, npeople)
    top_openers['openers.last_month']=SCR.GetTopOpenersSCR(31, startdate, enddate,idb, bots, npeople)

    # Top mergers
    top_mergers = {}
    top_mergers['mergers.last year']=SCR.GetTopMergersSCR(365, startdate, enddate,idb, bots, npeople)
    top_mergers['mergers.']=SCR.GetTopMergersSCR(0, startdate, enddate,idb, bots, npeople)
    top_mergers['mergers.last_month']=SCR.GetTopMergersSCR(31, startdate, enddate,idb, bots, npeople)

    # The order of the list item change so we can not check it
    top_all = dict(top_reviewers.items() +  top_openers.items() + top_mergers.items())
    createJSON (top_all, destdir+"/scr-top.json",False)

    return (top_all)

def quartersData(period, startdate, enddate, idb, destdir, bots):
    # Needed files. Ugly hack for date format
    people = SCR.GetPeopleListSCR("'"+startdate+"'", "'"+enddate+"'")
    createJSON(people, destdir+"/scr-people-all.json", False)
    companies = SCR.GetCompaniesSCRName("'"+startdate+"'", "'"+enddate+"'", idb)
    createJSON(companies, destdir+"/scr-companies-all.json", False)

    start = datetime.strptime(startdate, "%Y-%m-%d")
    start_quarter = (start.month-1)%3 + 1
    end = datetime.strptime(enddate, "%Y-%m-%d")
    end_quarter = (end.month-1)%3 + 1

    companies_quarters = {}
    people_quarters = {}

    quarters = (end.year - start.year) * 4 + (end_quarter - start_quarter)

    for i in range(0, quarters):
        year = start.year
        quarter = (i%4)+1
        logging.info("Analyzing companies and people quarter " + str(year) + " " +  str(quarter))
        data = GetCompaniesQuartersSCR(year, quarter, idb)
        companies_quarters[str(year)+" "+str(quarter)] = data
        data_people = GetPeopleQuartersSCR(year, quarter, idb, 25, bots)
        people_quarters[str(year)+" "+str(quarter)] = data_people
        start = start + relativedelta(months=3)
        print(start)
    print(companies_quarters)
    print(people_quarters)
    createJSON(companies_quarters, destdir+"/scr-companies-quarters.json")
    createJSON(people_quarters, destdir+"/scr-people-quarters.json")


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
    # vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)
    quartersData(period, opts.startdate, opts.enddate, opts.identities_db, opts.destdir, bots)
    top = topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots, opts.npeople)

    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir, top)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)

    logging.info("SCR data source analysis OK")

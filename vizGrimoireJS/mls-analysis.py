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
#
# Usage:
#     PYTHONPATH=../vizgrimoire LANG= R_LIBS=../../r-lib ./mls-analysis.py 
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
import MLS

def aggData(period, startdate, enddate, identities_db, destdir):
#    data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield)
#    agg = dataFrame2Dict(data)
    data = MLS.StaticMLSInfo(period, startdate, enddate, identities_db, rfield)
    agg = data


    if ('companies' in reports):
        data = MLS.AggMLSCompanies(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + data.items())

    if ('countries' in reports):
        data = MLS.AggMLSCountries(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + data.items())

    if ('domains' in reports):
        data = MLS.AggMLSDomains(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + data.items())

    # Tendencies
    for i in [7,30,365]:
        # period_data = dataFrame2Dict(vizr.GetDiffSentDays(period, enddate, i))
        period_data = MLS.GetDiffSentDays(period, enddate, i)
        agg = dict(agg.items() + period_data.items())
        period_data = MLS.GetDiffSendersDays(period, enddate, i)
        agg = dict(agg.items() + period_data.items())

    # Last Activity: to be removed
    for i in [7,14,30,60,90,180,365,730]:
        period_activity = MLS.lastActivity(i)
        agg = dict(agg.items() + period_activity.items())

    createJSON (agg, destdir+"/mls-static.json")

def tsData(period, startdate, enddate, identities_db, destdir, granularity, conf):

    evol = {}
#    data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield)
#    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())
    data = MLS.EvolMLSInfo(period, startdate, enddate, identities_db, rfield)
    evol = dict(evol.items() + completePeriodIds(data).items())


    if ('companies' in reports):
        data  = MLS.EvolMLSCompanies(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(data).items())

    if ('countries' in reports):
        data = MLS.EvolMLSCountries(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(data).items())

    if ('domains' in reports):
        data = MLS.EvolMLSDomains(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(data).items())

    createJSON (evol, destdir+"/mls-evolutionary.json")


def peopleData(period, startdate, enddate, identities_db, destdir):
    people =  dataFrame2Dict(vizr.GetListPeopleMLS(startdate, enddate))
    people = people['id']
    limit = 100
    if (len(people)<limit): limit = len(people);
    people = people[0:limit]

    createJSON(people, destdir+"/mls-people.json")

    for upeople_id in people:
        evol = vizr.GetEvolPeopleMLS(upeople_id, period, startdate, enddate)
        evol = completePeriodIds(dataFrame2Dict(evol))
        createJSON(evol, destdir+"/people-"+str(upeople_id)+"-mls-evolutionary.json")

        static = dataFrame2Dict(vizr.GetStaticPeopleMLS(upeople_id, startdate, enddate))
        createJSON(static, destdir+"/people-"+str(upeople_id)+"-mls-static.json")


def reposData(period, startdate, enddate, identities_db, destdir, conf, repofield):
    repos = dataFrame2Dict(vizr.reposNames(rfield, startdate, enddate))
    createJSON (repos, destdir+"/mls-lists.json")
    repos = repos['mailing_list_url']
    repos_files = [repo.replace('/', '_').replace("<","__").replace(">","___")
                   for repo in repos]
    createJSON(repos_files, destdir+"/mls-repos.json")

    for repo in repos:
        # Evol data   
        repo_name = "'"+repo+"'"
        data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield, ["repository", repo_name])
        data = completePeriodIds(dataFrame2Dict(data))
        listname_file = repo.replace("/","_")
        listname_file = listname_file.replace("<","__")
        listname_file = listname_file.replace(">","___")

        # TODO: Multilist approach. We will obsolete it in future
        createJSON (data, destdir+"/mls-"+listname_file+"-rep-evolutionary.json")
        # Multirepos filename
        createJSON (data, destdir+"/"+listname_file+"-mls-rep-evolutionary.json")

        top_senders = dataFrame2Dict(vizr.repoTopSenders (repo, identities_db, startdate, enddate, repofield))
        createJSON(top_senders, destdir+ "/"+listname_file+"-mls-rep-top-senders.json")

        # Static data
        data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield, ["repository", repo_name])
        data = dataFrame2Dict(data)
        # TODO: Multilist approach. We will obsolete it in future
        createJSON (data, destdir+"/"+listname_file+"-rep-static.json")
        # Multirepos filename
        createJSON (data, destdir+ "/"+listname_file+"-mls-rep-static.json")


def companiesData(period, startdate, enddate, identities_db, destdir):
    companies = valRtoPython(vizr.companiesNames(identities_db, startdate, enddate))
    createJSON(companies, destdir+"/mls-companies.json")

    for company in companies:
        company_name = "'"+company+ "'"
        data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield, ["company", company_name])
        data = completePeriodIds(dataFrame2Dict(data))
        createJSON(data, destdir+"/"+company+"-mls-com-evolutionary.json")

        top_senders = dataFrame2Dict(vizr.companyTopSenders (company, identities_db, startdate, enddate))
        createJSON(top_senders, destdir+"/"+company+"-mls-com-top-senders.json")

        data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield, ["company", company_name])
        data = dataFrame2Dict(data)
        createJSON(data, destdir+"/"+company+"-mls-com-static.json")


def countriesData(period, startdate, enddate, identities_db, destdir):

    countries = valRtoPython(vizr.countriesNames(identities_db, startdate, enddate)) 
    createJSON (countries, destdir + "/mls-countries.json")

    for country in countries:
        country_name = "'" + country + "'"
        type_analysis = ["country", country_name]
        data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
        data = completePeriodIds(dataFrame2Dict(data))
        createJSON (data, destdir+"/"+country+"-mls-cou-evolutionary.json")

        top_senders = dataFrame2Dict(vizr.countryTopSenders (country, identities_db, startdate, enddate))
        createJSON(top_senders, destdir+"/"+country+"-mls-cou-top-senders.json")

        data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
        data = dataFrame2Dict(data)
        createJSON (data, destdir+"/"+country+"-mls-cou-static.json")

def domainsData(period, startdate, enddate, identities_db, destdir):

    domains = valRtoPython(vizr.domainsNames(identities_db, startdate, enddate))
    createJSON(domains, destdir+"/mls-domains.json")

    for domain in domains:
        domain_name = "'"+domain+"'"
        type_analysis = ["domain", domain_name]
        data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
        data = completePeriodIds(dataFrame2Dict(data))
        createJSON(data, destdir+"/"+domain+"-mls-dom-evolutionary.json")

        data = vizr.domainTopSenders(domain, identities_db, startdate, enddate)
        data = dataFrame2Dict(data)
        createJSON(data, destdir+"/"+domain+"-mls-dom-top-senders.json")

        data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
        data = dataFrame2Dict(data)
        createJSON(data, destdir+"/"+domain+"-mls-dom-static.json")

def topData(period, startdate, enddate, identities_db, destdir, bots):
    top_senders_data = {}
    top_senders_data['senders.']=dataFrame2Dict(vizr.top_senders(0, startdate, enddate,identities_db,bots))
    top_senders_data['senders.last year']=dataFrame2Dict(vizr.top_senders(365, startdate, enddate,identities_db, bots))
    top_senders_data['senders.last month']=dataFrame2Dict(vizr.top_senders(31, startdate, enddate,identities_db,bots))

    createJSON (top_senders_data, destdir+"/mls-top.json", False)

def demographics(enddate, destdir):
    vizr.ReportDemographicsAgingMLS(enddate, destdir)
    vizr.ReportDemographicsBirthMLS(enddate, destdir)

def timeToAttend(destdir):
    ## Which quantiles we're interested in
    quantiles_spec = [0.99,0.95,0.5,0.25]

    ## Yearly quantiles of time to attention (minutes)
    ## Monthly quantiles of time to attention (hours)
    ## JSON files generated from VizR
    vizr.ReportTimeToAttendMLS(destdir)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting MLS data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # filtered bots

    bots = ['wikibugs','gerrit-wm','wikibugs_','wm-bot','','Translation updater bot','jenkins-bot']
    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"
    # rfield = vizr.reposField()
    rfield = "mailing_list_url"

    # Working at the same time with VizR and VizPy yet
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)

    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts, rfield)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('domains' in reports):
        domainsData (period, startdate, enddate, opts.identities_db, opts.destdir)

    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)
    demographics(opts.enddate, opts.destdir)
    timeToAttend(opts.destdir)
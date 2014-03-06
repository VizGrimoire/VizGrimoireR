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
import SCM

def aggData(period, startdate, enddate, identities_db, destdir):
    # data = dataFrame2Dict(vizr.GetSCMStaticData(period, startdate, enddate, identities_db))
    data = SCM.GetSCMStaticData(period, startdate, enddate, identities_db, None)
    agg = data
    static_url = SCM.StaticURL()
    agg = dict(agg.items() + static_url.items())

    if ('companies' in reports):
        data = SCM.evol_info_data_companies (startdate, enddate)
        agg = dict(agg.items() + data.items())

    if ('countries' in reports): 
        data = SCM.evol_info_data_countries (startdate, enddate)
        agg = dict(agg.items() + data.items())

    if ('domains' in reports):
        data = SCM.evol_info_data_domains (startdate, enddate)
        agg = dict(agg.items() + data.items())

    data = SCM.GetCodeCommunityStructure(period, startdate, enddate, identities_db)
    agg = dict(agg.items() + data.items())

    # TODO: repeated data
    # data = dataFrame2Dict(vizr.GetDiffCommitsDays(period, enddate, 365))
    # agg = dict(agg.items() + data.items())

    # Tendencies    
    for i in [7,30,365]:
        data = SCM.GetDiffCommitsDays(period, enddate, identities_db, i)
        agg = dict(agg.items() + data.items())
        data = SCM.GetDiffAuthorsDays(period, enddate, identities_db, i)
        agg = dict(agg.items() + data.items())
        data = SCM.GetDiffFilesDays(period, enddate, identities_db, i)
        agg = dict(agg.items() + data.items())
        data = SCM.GetDiffLinesDays(period, enddate, identities_db, i)
        agg = dict(agg.items() + data.items())

    # Last Activity: to be removed
    for i in [7,14,30,60,90,180,365,730]:
        data = SCM.last_activity(i)
        agg = dict(agg.items() + data.items())

    # Fields with wrong data in R
    skip_fields = ['percentage_removed_lines_30','percentage_added_lines_30','diff_netadded_lines_30','diff_netremoved_lines_30']
    createJSON (agg, destdir+"/scm-static.json", True, skip_fields)

def tsData(period, startdate, enddate, identities_db, destdir, granularity, conf):
#    data = vizr.GetSCMEvolutionaryData(period, startdate, enddate, identities_db)
#    evol_data = completePeriodIds(dataFrame2Dict(data))
    data = SCM.GetSCMEvolutionaryData(period, startdate, enddate, identities_db, None)
    evol_data = completePeriodIds(data)

    if ('companies' in reports) :
        data = SCM.EvolCompanies(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(data).items())

    if ('countries' in reports) :
        data = SCM.EvolCountries(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(data).items())

    if ('domains' in reports) :
        data = SCM.EvolDomains(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(data).items())
 
    createJSON (evol_data, destdir+"/scm-evolutionary.json")

def peopleData(period, startdate, enddate, identities_db, destdir, top_authors_data):
    top = top_authors_data['authors.']["id"]
    top += top_authors_data['authors.last year']["id"]
    top += top_authors_data['authors.last month']["id"]
    # remove duplicates
    people = list(set(top))
    # the order is not the same than in R json
    createJSON(people, destdir+"/scm-people.json", False)

    for upeople_id in people :
        evol_data = SCM.GetEvolPeopleSCM(upeople_id, period, startdate, enddate)
        evol_data = completePeriodIds(evol_data)
        createJSON (evol_data, destdir+"/people-"+str(upeople_id)+"-scm-evolutionary.json")

        agg = SCM.GetStaticPeopleSCM(upeople_id,  startdate, enddate)
        createJSON (agg, destdir+"/people-"+str(upeople_id)+"-scm-static.json")

    pass

def reposData(period, startdate, enddate, identities_db, destdir, conf):
    # repos  = dataFrame2Dict(vizr.repos_name(startdate, enddate))
    repos  = SCM.repos_name(startdate, enddate)
    repos = repos['name']
    if not isinstance(repos, (list)): 
        repos = [repos]
        createJSON(repos, destdir+"/scm-repos.json", False)
    else:
        createJSON(repos, destdir+"/scm-repos.json")

    for repo in repos :
        repo_name = "'"+ repo+ "'"
        print (repo_name)

        evol_data = SCM.GetSCMEvolutionaryData(period, startdate, enddate, identities_db, ["repository", repo_name])
        evol_data = completePeriodIds(evol_data)
        createJSON(evol_data, destdir+"/"+repo+"-scm-rep-evolutionary.json")

        agg = SCM.GetSCMStaticData(period, startdate, enddate, identities_db, ["repository", repo_name])
        createJSON(agg, destdir+"/"+repo+"-scm-rep-static.json")

def companiesData(period, startdate, enddate, identities_db, destdir, bots, npeople):
    companies  = SCM.companies_name_wo_affs(bots, startdate, enddate)
    companies = companies['name']
    createJSON(companies, destdir+"/scm-companies.json")

    for company in companies:
        company_name = "'"+ company+ "'"
        print (company_name)

        evol_data = SCM.GetSCMEvolutionaryData(period, startdate, enddate, identities_db, ["company", company_name])
        evol_data = completePeriodIds(evol_data)
        createJSON(evol_data, destdir+"/"+company+"-scm-com-evolutionary.json")

        agg = SCM.GetSCMStaticData(period, startdate, enddate, identities_db, ["company", company_name])
        createJSON(agg, destdir+"/"+company+"-scm-com-static.json")

        top_authors = SCM.company_top_authors(company_name, startdate, enddate, npeople)
        createJSON(top_authors, destdir+"/"+company+"-scm-com-top-authors.json", False)

        for i in [2006,2009,2012]:
            data = SCM.company_top_authors_year(company_name, i, npeople)
            createJSON(data, destdir+"/"+company+"-scm-top-authors_"+str(i)+".json", False)

    commits =  SCM.GetCommitsSummaryCompanies(period, startdate, enddate, opts.identities_db, 10)
    createJSON (commits, destdir+"/scm-companies-commits-summary.json")

def countriesData(period, startdate, enddate, identities_db, destdir):
    countries  = SCM.scm_countries_names(identities_db,startdate, enddate)
    countries = countries['name']
    createJSON(countries, destdir+"/scm-countries.json")

    for country in countries:
        print (country)
        country_name = "'"+country+"'"

        evol_data = SCM.GetSCMEvolutionaryData(period, startdate, enddate, identities_db, ["country", country_name])
        evol_data = completePeriodIds(evol_data)
        createJSON (evol_data, destdir+"/"+country+"-scm-cou-evolutionary.json")

        agg = SCM.GetSCMStaticData(period, startdate, enddate, identities_db, ["country", country_name])
        createJSON (agg, destdir+"/"+country+"-scm-cou-static.json")

def domainsData(period, startdate, enddate, identities_db, destdir):
    domains = SCM.scm_domains_names(identities_db,startdate, enddate)
    domains = domains['name']
    createJSON(domains, destdir+"/scm-domains.json")
    # Some R ts are wrong
    bad_R_json_domains = ['gerrit','gmx','emsenhuber','bitergia']

    for domain in domains :
        domain_name = "'"+domain+"'"
        print (domain_name)

        evol_data = SCM.GetSCMEvolutionaryData(period, startdate, enddate, identities_db, ["domain", domain_name])
        evol_data = completePeriodIds(evol_data)
        if domain in bad_R_json_domains:
            createJSON(evol_data, destdir+"/"+domain+"-scm-dom-evolutionary.json", False)
        else:
            createJSON(evol_data, destdir+"/"+domain+"-scm-dom-evolutionary.json")

        agg = SCM.GetSCMStaticData(period, startdate, enddate, identities_db, ["domain", domain_name])
        createJSON(agg, destdir+ "/"+domain+"-scm-dom-static.json")


def companies_countriesData(period, startdate, enddate, identities_db, destdir):
    companies = SCM.companies_name(startdate, enddate)
    companies = companies['name']
    for company in companies:
        company_name = "'"+company+ "'"
        countries  = SCM.scm_countries_names(identities_db,startdate, enddate)
        countries = countries['name']
        for country in countries :
            print (country, "=>", company)
            data = SCM.scm_companies_countries_evol(identities_db, company, country, nperiod, startdate, enddate)
            data = completePeriodIds(data)
            createJSON (data, destdir + "/"+company+"_"+country+"-scm-evolutionary.json", False)

            # Not implemented in original R
            # data = vizr.scm_countries_static(identities_db, country, startdate, enddate)
            # createJSON (dataFrame2Dict(data), destdir + "/"+company+"_"+country+"-scm-static.json", False)

def topData(period, startdate, enddate, identities_db, destdir, bots, npeople):
    top_authors_data =  {}
    top_authors_data['authors.'] = SCM.top_people(0, startdate, enddate, "author" , "" , npeople)
    top_authors_data['authors.last year']= SCM.top_people(365, startdate, enddate, "author", "", npeople)
    top_authors_data['authors.last month']= SCM.top_people(31, startdate, enddate, "author", "", npeople)
    createJSON (top_authors_data, destdir+"/scm-top.json")

    # Top files
    top_files_modified_data = SCM.top_files_modified()

    return top_authors_data

def microStudies(enddate, destdir):
    # Studies implemented in R

    # Demographics
    vizr.ReportDemographicsAgingSCM(enddate, destdir)
    vizr.ReportDemographicsBirthSCM(enddate, destdir)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting SCM data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    nperiod = getPeriod(opts.granularity, True)
    reports = opts.reports.split(",")
    # filtered bots

    bots = ["-Bot", "-Individual", "-Unknown"]
    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    # Working at the same time with VizR and VizPy yet
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)
    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)

    if ('domains' in reports):
        domainsData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir, bots, opts.npeople)
    if ('companies-countries' in reports):
        companies_countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    # pretty slow!
    top = topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots, opts.npeople)
    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir, top)
    microStudies(opts.enddate, opts.destdir)

    logging.info("SCM data source analysis OK")

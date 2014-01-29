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
# import MLS

def aggData(period, startdate, enddate, identities_db, destdir):
    data = dataFrame2Dict(vizr.GetSCMStaticData(period, startdate, enddate, identities_db))
    agg = data
    static_url = dataFrame2Dict(vizr.StaticURL())
    agg = dict(agg.items() + static_url.items())

    if ('companies' in reports):
        data = dataFrame2Dict(vizr.evol_info_data_companies (startdate, enddate))
        agg = dict(agg.items() + data.items())

    if ('countries' in reports): 
        data = dataFrame2Dict(vizr.evol_info_data_countries (startdate, enddate))
        agg = dict(agg.items() + data.items())

    if ('domains' in reports):
        data = dataFrame2Dict(vizr.evol_info_data_domains (startdate, enddate))
        agg = dict(agg.items() + data.items())

    data = dataFrame2Dict(vizr.GetCodeCommunityStructure(period, startdate, enddate, identities_db))
    agg = dict(agg.items() + data.items())

    # TODO: repeated data
    # data = dataFrame2Dict(vizr.GetDiffCommitsDays(period, enddate, 365))
    # agg = dict(agg.items() + data.items())

    # Tendencies    
    for i in [7,30,365]:
        data = dataFrame2Dict(vizr.GetDiffCommitsDays(period, enddate, i))
        agg = dict(agg.items() + data.items())
        data = dataFrame2Dict(vizr.GetDiffAuthorsDays(period, enddate, identities_db, i))
        agg = dict(agg.items() + data.items())
        data = dataFrame2Dict(vizr.GetDiffFilesDays(period, enddate, identities_db, i))
        agg = dict(agg.items() + data.items())
        data = dataFrame2Dict(vizr.GetDiffLinesDays(period, enddate, identities_db, i))
        agg = dict(agg.items() + data.items())

    # Last Activity: to be removed
    for i in [7,14,30,60,90,180,365,730]:
        data = dataFrame2Dict(vizr.last_activity(i))
        agg = dict(agg.items() + data.items())

    createJSON (agg, destdir+"/scm-static.json")

def tsData(period, startdate, enddate, identities_db, destdir, granularity, conf):
    data = vizr.GetSCMEvolutionaryData(period, startdate, enddate, identities_db)
    evol_data = completePeriodIds(dataFrame2Dict(data))

    if ('companies' in reports) :
        data = vizr.EvolCompanies(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(dataFrame2Dict(data)).items())

    if ('countries' in reports) :
        data = vizr.EvolCountries(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(dataFrame2Dict(data)).items())

    if ('domains' in reports) :
        data = vizr.EvolDomains(period, startdate, enddate)
        evol_data = dict(evol_data.items() + completePeriodIds(dataFrame2Dict(data)).items())
 
    createJSON (evol_data, destdir+"/scm-evolutionary.json")

def peopleData(period, startdate, enddate, identities_db, destdir):
#    all.top.authors = top_authors_data[['authors.']]$id
#    all.top.authors = append(all.top.authors, top_authors_data[['authors.last year']]$id)
#    all.top.authors = append(all.top.authors, top_authors_data[['authors.last month']]$id)
#    all.top.authors = unique(all.top.authors)
#    createJSON(all.top.authors, destdir+"/scm-people.json")
#
#    for (upeople_id in all.top.authors) :
#        evol_data = GetEvolPeopleSCM(upeople_id, period, 
#                startdate, enddate)
#        evol_data = completePeriodIds(evol_data)
#        evol_data[is.na(evol_data)] = 0
#        createJSON (evol_data, destdir+"/people-",
#                        upeople_id,"-scm-evolutionary.json")
#        agg = GetStaticPeopleSCM(upeople_id, 
#                startdate, enddate)
#        createJSON (agg, destdir+"/people-",
#                        upeople_id,"-scm-static.json")
#    

    pass

def reposData(period, startdate, enddate, identities_db, destdir, conf):
#    repos  = repos_name(startdate, enddate)
#    repos = repos$name
#    createJSON(repos, destdir+"/scm-repos.json")
#
#    for (repo in repos) :
#        repo_name = "'", repo, "'"
#        repo_aux = "", repo, ""
#        print (repo_name)
#
#        evol_data = GetSCMEvolutionaryData(period, startdate, enddate, identities_db, list("repository", repo_name))
#        evol_data = completePeriodIds(evol_data)
#        evol_data = evol_data[order(evol_data$id), ]
#        evol_data[is.na(evol_data)] = 0
#
#        createJSON(evol_data, destdir, "/",repo_aux,"-scm-rep-evolutionary.json")
#
#        agg = GetSCMStaticData(period, startdate, enddate, identities_db, list("repository", repo_name))
#
#        createJSON(agg, destdir, "/",repo_aux,"-scm-rep-static.json")        
#    
    pass

def companiesData(period, startdate, enddate, identities_db, destdir):
#    companies  = companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), startdate, enddate)
#    companies = companies$name
#    createJSON(companies, destdir+"/scm-companies.json")
#
#    for (company in companies):
#        company_name = "'", company, "'"
#        company_aux = "", company, ""
#        print (company_name)
#
#        ######
#        #Evolutionary data per company
#        ######    
#        # 1- Retrieving and merging info  
#        evol_data = GetSCMEvolutionaryData(period, startdate, enddate, identities_db, list("company", company_name))
#
#        evol_data = completePeriodIds(evol_data)
#        evol_data = evol_data[order(evol_data$id), ]
#        evol_data[is.na(evol_data)] = 0
#
#        # 2- Creation of JSON file
#        createJSON(evol_data, destdir+"/",company_aux,"-scm-com-evolutionary.json")
#
#        ########
#        #Static data per company
#        ########
#        agg = GetSCMStaticData(period, startdate, enddate, identities_db, list("company", company_name))
#
#        createJSON(agg, destdir+"/",company_aux,"-scm-com-static.json")
#
#        top_authors = company_top_authors(company_name, startdate, enddate)
#        createJSON(top_authors, destdir+"/",company_aux,"-scm-com-top-authors.json")
#        top_authors_2006 = company_top_authors_year(company_name, 2006)
#        createJSON(top_authors_2006, destdir+"/",company_aux,"-scm-top-authors_2006.json")
#        top_authors_2009 = company_top_authors_year(company_name, 2009)
#        createJSON(top_authors_2009, destdir+"/",company_aux,"-scm-top-authors_2009.json")
#        top_authors_2012 = company_top_authors_year(company_name, 2012)
#        createJSON(top_authors_2012, destdir+"/",company_aux,"-scm-top-authors_2012.json")    
#    
    pass

def countriesData(period, startdate, enddate, identities_db, destdir):
#    countries  = scm_countries_names(identities_db,startdate, enddate)
#    countries = countries$name
#    createJSON(countries, destdir+"/scm-countries.json")
#
#    for (country in countries) :
#        if (is.na(country)) next
#        print (country)
#        country_name = "'", country, "'"
#
#        evol_data = GetSCMEvolutionaryData(period, startdate, enddate, identities_db, list("country", country_name))
#        # evol_data = EvolCommits(period, startdate, enddate, identities_db, country=country_name)
#        evol_data = completePeriodIds(evol_data)
#        # evol_data = evol_data[order(evol_data$id), ]
#        # evol_data[is.na(evol_data)] = 0
#
#        createJSON (evol_data, destdir, "/",country,"-scm-cou-evolutionary.json",sep=''))
#
#        # data = scm_countries_static(identities_db, country, startdate, enddate)
#        agg = GetSCMStaticData(period, startdate, enddate, identities_db, list("country", country_name))
#        createJSON (agg, destdir, "/",country,"-scm-cou-static.json",sep=''))
#    

    pass

def domainsData(period, startdate, enddate, identities_db, destdir):
#    domains = scm_domains_names(identities_db,startdate, enddate)
#    domains = domains$name
#    createJSON(domains, destdir+"/scm-domains.json")
#
#    for (domain in domains) :
#        domain_name = "'", domain, "'"
#        domain_aux = "", domain, ""
#        print (domain_name)

#        evol_data = GetSCMEvolutionaryData(period, startdate, enddate, identities_db, list("domain", domain_name))
#        evol_data = completePeriodIds(evol_data)
#        evol_data = evol_data[order(evol_data$id), ]
#        evol_data[is.na(evol_data)] = 0
#
#        createJSON(evol_data, destdir, "/", domain_aux,"-scm-dom-evolutionary.json")
#
#        agg = GetSCMStaticData(period, startdate, enddate, identities_db, list("domain", domain_name))
#
#        createJSON(agg, destdir, "/", domain_aux, "-scm-dom-static.json")
#    
    pass


def companies_countriesData(period, startdate, enddate, identities_db, destdir):
#    companies  = companies_name(startdate, enddate)
#    companies = companies$name
#    for (company in companies):
#        countries  = scm_countries_names(identities_db,startdate, enddate)
#    countries = countries$name
#    for (country in countries) :
#            company_name = c("'", company, "'"), collapse='')
#            company_aux = c("", company, ""), collapse='')
#
#            ###########
#            if (is.na(country)) next
#            print (country, "=>", company))
#            data = scm_companies_countries_evol(identities_db, company, country, nperiod, startdate, enddate)
#            if (length(data) == 0) :
#                data = data.frame(id=numeric(0),commits=numeric(0),authors=numeric(0))
#            
#
#            data = completeZeroPeriod(data, nperiod, conf$str_startdate, conf$str_enddate)
#            data$week = as.Date(conf$str_startdate) + data$id * nperiod
#            data$date  = toTextDate(GetYear(data$week), GetMonth(data$week)+1)
#            data = data[order(data$id), ]
#            createJSON (data, "data/json/companycountry/",company,".",country,"-scm-evolutionary.json",sep=''))
#
#            data = scm_countries_static(identities_db, country, startdate, enddate)
#            createJSON (data, "data/json/companycountry/",company,".",country,"-scm-static.json",sep=''))
#
#            #################
#
#
#        
#    
    pass


def topData(period, startdate, enddate, identities_db, destdir, bots):
#    top_authors_data = top_authors(startdate, enddate)
#    top_authors_data = list()
#    top_authors_data[['authors.']] = top_people(0, startdate, enddate, "author" , "" )
#    top_authors_data[['authors.last year']]= top_people(365, startdate, enddate, "author", "")
#    top_authors_data[['authors.last month']]= top_people(31, startdate, enddate, "author", "")
#    createJSON (top_authors_data, destdir+"/scm-top.json")
#    
#    # Top files
#    top_files_modified_data = top_files_modified()
    pass


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting MLS data source analysis")
    opts = read_options()
    period = getPeriod(opts.granularity)
    reports = opts.reports.split(",")
    # filtered bots

    bots = ["-Bot", "-Individual", "-Unknown"]
    # TODO: hack because VizR library needs. Fix in lib in future
    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    # Working at the same time with VizR and VizPy yet
    vizr.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    # GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)

    if ('people' in reports):
        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('repositories' in reports):
        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts)
    if ('countries' in reports):
        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies' in reports):
        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)
    if ('companies-countries' in reports):
        companies_countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)

    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)
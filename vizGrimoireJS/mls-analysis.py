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

    data = vizr.StaticMLSInfo(period, startdate, enddate, identities_db, rfield)
    agg = dataFrame2Dict(data)

    if ('companies' in reports):
        data = vizr.AggMLSCompanies(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + dataFrame2Dict(data).items())

    if ('countries' in reports):
        data = vizr.AggMLSCountries(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + dataFrame2Dict(data).items())

    if ('domains' in reports):
        data = vizr.AggMLSDomains(period, startdate, enddate, identities_db)
        agg = dict(agg.items() + dataFrame2Dict(data).items())

    # Tendencies
    for i in [7,30,365]:
        period_data = dataFrame2Dict(vizr.GetDiffSentDays(period, enddate, i))
        agg = dict(agg.items() + period_data.items())
        period_data = dataFrame2Dict(vizr.GetDiffSendersDays(period, enddate, i))
        agg = dict(agg.items() + period_data.items())

    # Last Activity: to be removed
    for i in [7,14,30,60,90,180,365,730]:
        period_activity = dataFrame2Dict(vizr.lastActivity(i))
        agg = dict(agg.items() + period_activity.items())

    createJSON (agg, destdir+"/mls-static.json")

def tsData(period, startdate, enddate, identities_db, destdir, granularity, conf):

    evol = {}
    data = vizr.EvolMLSInfo(period, startdate, enddate, identities_db, rfield)
    evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())

    if ('companies' in reports):
        data  = vizr.EvolMLSCompanies(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())

    if ('countries' in reports):
        data = vizr.EvolMLSCountries(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())

    if ('domains' in reports):
        data = vizr.EvolMLSDomains(period, startdate, enddate, identities_db)
        evol = dict(evol.items() + completePeriodIds(dataFrame2Dict(data)).items())

    createJSON (evol, destdir+"/mls-evolutionary.json")


def peopleData(period, startdate, enddate, identities_db, destdir):
    pass
#    people = GetListPeopleMLS(startdate, enddate)
#    people = people$id
#    limit = 100
#    if (length(people)<limit) limit = length(people);
#    people = people[1:limit]
#    createJSON(people, paste(destdir,"/mls-people.json",sep=''))
#
#    for (upeople_id in people){
#        evol = GetEvolPeopleMLS(upeople_id, period, startdate, enddate)
#        evol = completePeriodIds(evol, conf$granularity, conf)
#        evol[is.na(evol)] = 0
#        createJSON(evol, paste(destdir,"/people-",upeople_id,"-mls-evolutionary.json", sep=''))
#
#        static = GetStaticPeopleMLS(upeople_id, startdate, enddate)
#        createJSON(static, paste(destdir,"/people-",upeople_id,"-mls-static.json", sep=''))
#

def reposData(period, startdate, enddate, identities_db, destdir, conf):
    pass
#    repos = reposNames(rfield, startdate, enddate)
#    createJSON (repos, paste(destdir,"/mls-lists.json", sep=''))
#    repos = repos$mailing_list
#    repos_file_names = gsub("/","_",repos)
#    repos_file_names = gsub("<","__",repos_file_names)
#    repos_file_names = gsub(">","___",repos_file_names)
#    createJSON(repos_file_names, paste(destdir,"/mls-repos.json", sep=''))
#
#
#    for (repo in repos):    
#        # Evol data   
#        repo_name = paste("'", repo, "'", sep="")
#        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("repository", repo_name)))
#        data = completePeriodIds(data, conf$granularity, conf)        
#        listname_file = gsub("/","_",repo)
#        listname_file = gsub("<","__",listname_file)
#        listname_file = gsub(">","___",listname_file)
#
#        # TODO: Multilist approach. We will obsolete it in future
#        createJSON (data, paste(destdir,"/mls-",listname_file,"-rep-evolutionary.json",sep=''))
#        # Multirepos filename
#        createJSON (data, paste(destdir,"/",listname_file,"-mls-rep-evolutionary.json",sep=''))
#
#        top_senders = repoTopSenders (repo, identities_db, startdate, enddate)
#        createJSON(top_senders, paste(destdir, "/",listname_file,"-mls-rep-top-senders.json", sep=''))        
#
#        # Static data
#        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("repository", repo_name)))
#        # TODO: Multilist approach. We will obsolete it in future
#        createJSON (data, paste(destdir, "/",listname_file,"-rep-static.json",sep=''))
#        # Multirepos filename
#        createJSON (data, paste(destdir, "/",listname_file,"-mls-rep-static.json",sep=''))    
#

def companiesData(period, startdate, enddate, identities_db, destdir):
    pass
#    companies = companiesNames(identities_db, startdate, enddate)
#    createJSON(companies, paste(destdir,"/mls-companies.json",sep=''))
#
#    for (company in companies){
#        print (company)
#        company_name = paste("'", company, "'", sep="")
#        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("company", company_name)))
#        data = completePeriodIds(data, conf$granularity, conf)
#        createJSON(data, paste(destdir,"/",company,"-mls-com-evolutionary.json", sep=''))
#
#        top_senders = companyTopSenders (company, identities_db, startdate, enddate)
#        createJSON(top_senders, paste(destdir,"/",company,"-mls-com-top-senders.json", sep=''))
#
#        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("company", company_name)))
#        createJSON(data, paste(destdir,"/",company,"-mls-com-static.json", sep=''))
#

def countriesData(period, startdate, enddate, identities_db, destdir):
    pass
#    countries = countriesNames(identities_db, startdate, enddate) 
#    createJSON (countries, paste(destdir, "/mls-countries.json",sep=''))
#
#    for (country in countries):
#        if (is.na(country)) next
#        print (country)
#        country_name = paste("'", country, "'", sep="")
#        type_analysis = list("country", country_name)
#        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
#        data = completePeriodIds(data, conf$granularity, conf)
#        createJSON (data, paste(destdir,"/",country,"-mls-cou-evolutionary.json",sep=''))
#
#        top_senders = countryTopSenders (country, identities_db, startdate, enddate)
#        createJSON(top_senders, paste(destdir,"/",country,"-mls-cou-top-senders.json", sep=''))
#
#        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, list("country", country_name))
#        createJSON (data, paste(destdir,"/",country,"-mls-cou-static.json",sep=''))
#

def domainsData(period, startdate, enddate, identities_db, destdir):
    pass
#    domains = domainsNames(identities_db, startdate, enddate)
#    createJSON(domains, paste(destdir,"/mls-domains.json",sep=''))
#
#    for (domain in domains){
#        print (domain)
#        domain_name = paste("'", domain, "'", sep="")
#        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("domain", domain_name)))
#        data = completePeriodIds(data, conf$granularity, conf)
#        createJSON(data, paste(destdir,"/",domain,"-mls-dom-evolutionary.json", sep=''))
#
#        top_senders = domainTopSenders (domain, identities_db, startdate, enddate)
#        createJSON(top_senders, paste(destdir,"/",domain,"-mls-dom-top-senders.json", sep=''))
#
#        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("domain", domain_name)))
#        createJSON(data, paste(destdir,"/",domain,"-mls-dom-static.json", sep=''))
#


def topData(period, startdate, enddate, identities_db, destdir, bots):
    pass
#    top_senders_data = list()
#    top_senders_data[['senders.']]=top_senders(0, startdate, enddate,identities_db,c("-Bot"))
#    top_senders_data[['senders.last year']]=top_senders(365, startdate, enddate,identities_db,c("-Bot"))
#    top_senders_data[['senders.last month']]=top_senders(31, startdate, enddate,identities_db,c("-Bot"))
#
#    createJSON (top_senders_data, paste(destdir,"/mls-top.json",sep=''))

def demographics(enddate):
    pass
#    d = new ("Demographics","mls",6)
#    people = Aging(d)
#    people$age = as.Date(conf$str_enddate) - as.Date(people$firstdate)
#    people$age[people$age < 0 ] = 0
#    aux = data.frame(people["id"], people["age"])
#    new = list()
#    new[['date']] = conf$str_enddate
#    new[['persons']] = aux
#    createJSON (new, paste(c(destdir, "/mls-demographics-aging.json"), collapse=''))
#
#    newcomers = Birth(d)
#    newcomers$age = as.Date(conf$str_enddate) - as.Date(newcomers$firstdate)
#    newcomers$age[newcomers$age < 0 ] = 0
#    aux = data.frame(newcomers["id"], newcomers["age"])
#    new = list()
#    new[['date']] = conf$str_enddate
#    new[['persons']] = aux
#    createJSON (new, paste(c(destdir, "/mls-demographics-birth.json"), collapse=''))

def timeToAttend():
    pass
#    ## Quantiles
#    ## Which quantiles we're interested in
#    quantiles_spec = c(.99,.95,.5,.25)
#    
#    ## Replied messages: time ticket was submitted, first replied
#    replied = new ("MLSTimes")
#    # print(replied)
#    
#    ## Yearly quantiles of time to attention (minutes)
#    events.toattend = new ("TimedEvents",
#                            replied$submitted_on, replied$toattend %/% 60)
#    # print(events.toattend)
#    quantiles = QuantilizeYears (events.toattend, quantiles_spec)
#    JSON(quantiles, paste(c(destdir,'/mls-quantiles-year-time_to_attention_min.json'), collapse=''))
#    
#    ## Monthly quantiles of time to attention (hours)
#    events.toattend.hours = new ("TimedEvents",
#                                  replied$submitted_on, replied$toattend %/% 3600)
#    quantiles.month = QuantilizeMonths (events.toattend.hours, quantiles_spec)
#    JSON(quantiles.month, paste(c(destdir,'/mls-quantiles-month-time_to_attention_hour.json'), collapse=''))

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
    # GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)

    tsData (period, startdate, enddate, opts.identities_db, opts.destdir, opts.granularity, opts)
    aggData(period, startdate, enddate, opts.identities_db, opts.destdir)
#
#    if ('people' in reports):
#        peopleData (period, startdate, enddate, opts.identities_db, opts.destdir)
#    if ('repositories' in reports):
#        reposData (period, startdate, enddate, opts.identities_db, opts.destdir, opts)
#    if ('countries' in reports):
#        countriesData (period, startdate, enddate, opts.identities_db, opts.destdir)
#    if ('companies' in reports):
#        companiesData (period, startdate, enddate, opts.identities_db, opts.destdir)

    topData(period, startdate, enddate, opts.identities_db, opts.destdir, bots)
    demographics(enddate)
    timeToAttend()
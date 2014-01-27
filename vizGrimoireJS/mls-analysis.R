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
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo San Felix <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -h for help < < mls-analysis.R

library("vizgrimoire")
library("ISOweek")

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)
destdir <- conf$destination

# period of time
if (conf$granularity == 'years') { period = 'year'
} else if (conf$granularity == 'months') { period = 'month'
} else if (conf$granularity == 'weeks') { period = 'week'
} else if (conf$granularity == 'days'){ period = 'day'
} else {stop(paste("Incorrect period:",conf$granularity))}

identities_db = conf$identities_db

# multireport
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]

# dates
startdate <- conf$startdate
enddate <- conf$enddate

#
# GLOBAL
#
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 
rfield = reposField()

data <- EvolMLSInfo(period, startdate, enddate, identities_db, rfield)

if ('companies' %in% reports) {
    companies <- EvolMLSCompanies(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, companies, all = TRUE)
}
if ('countries' %in% reports) {
    countries <- EvolMLSCountries(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, countries, all = TRUE)
}
if ('domains' %in% reports) {
    domains <- EvolMLSDomains(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, domains, all = TRUE)
}


data <- completePeriodIds(data, conf$granularity, conf)

createJSON (data, paste(destdir,"/mls-evolutionary.json", sep=''))


static_data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield)

if ('companies' %in% reports) {
    companies <- AggMLSCompanies(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, companies, all = TRUE)
}
if ('countries' %in% reports) {
    countries <- AggMLSCountries(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, countries, all = TRUE)
}
if ('domains' %in% reports) {
    domains <- AggMLSDomains(period, conf$startdate, conf$enddate, identities_db)
    data = merge(data, domains, all = TRUE)
}



latest_activity7 <- lastActivity(7)
latest_activity14 <- lastActivity(14)
latest_activity30 <- lastActivity(30)
latest_activity60 <- lastActivity(60)
latest_activity90 <- lastActivity(90)
latest_activity180 <- lastActivity(180)
latest_activity365 <- lastActivity(365)
latest_activity730 <- lastActivity(730)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity14)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity60)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity180)
static_data = merge(static_data, latest_activity365)
static_data = merge(static_data, latest_activity730)

sent_7 = GetDiffSentDays(period, conf$enddate, 7)
sent_30 = GetDiffSentDays(period, conf$enddate, 30)
sent_365 = GetDiffSentDays(period, conf$enddate, 365)
senders_7 = GetDiffSendersDays(period, conf$enddate, 7)
senders_30 = GetDiffSendersDays(period, conf$enddate, 30)
senders_365 = GetDiffSendersDays(period, conf$enddate, 365)
static_data = merge(static_data, sent_7)
static_data = merge(static_data, sent_30)
static_data = merge(static_data, sent_365)

static_data = merge(static_data, senders_7)
static_data = merge(static_data, senders_30)
static_data = merge(static_data, senders_365)

createJSON (static_data, paste(destdir,"/mls-static.json",sep=''))


if ('repositories' %in% reports) {
    repos <- reposNames(rfield, startdate, enddate)
    createJSON (repos, paste(destdir,"/mls-lists.json", sep=''))
    repos <- repos$mailing_list
    repos_file_names = gsub("/","_",repos)
    repos_file_names = gsub("<","__",repos_file_names)
    repos_file_names = gsub(">","___",repos_file_names)
    createJSON(repos_file_names, paste(destdir,"/mls-repos.json", sep=''))


    for (repo in repos) {    
        # Evol data   
        repo_name = paste("'", repo, "'", sep="")
        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("repository", repo_name)))
        data <- completePeriodIds(data, conf$granularity, conf)        
        listname_file = gsub("/","_",repo)
        listname_file = gsub("<","__",listname_file)
        listname_file = gsub(">","___",listname_file)

        # TODO: Multilist approach. We will obsolete it in future
        createJSON (data, paste(destdir,"/mls-",listname_file,"-rep-evolutionary.json",sep=''))
        # Multirepos filename
        createJSON (data, paste(destdir,"/",listname_file,"-mls-rep-evolutionary.json",sep=''))

        top_senders = repoTopSenders (repo, identities_db, startdate, enddate, rfield)
        createJSON(top_senders, paste(destdir, "/",listname_file,"-mls-rep-top-senders.json", sep=''))        

        # Static data
        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("repository", repo_name)))
        # TODO: Multilist approach. We will obsolete it in future
    	createJSON (data, paste(destdir, "/",listname_file,"-rep-static.json",sep=''))
    	# Multirepos filename
    	createJSON (data, paste(destdir, "/",listname_file,"-mls-rep-static.json",sep=''))    
    }
}

if ('countries' %in% reports) {
    countries <- countriesNames(identities_db, startdate, enddate) 
    createJSON (countries, paste(destdir, "/mls-countries.json",sep=''))

    for (country in countries) {
        if (is.na(country)) next
        print (country)
        country_name = paste("'", country, "'", sep="")
        type_analysis = list("country", country_name)
        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, type_analysis)
        data <- completePeriodIds(data, conf$granularity, conf)
        createJSON (data, paste(destdir,"/",country,"-mls-cou-evolutionary.json",sep=''))

        top_senders = countryTopSenders (country, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir,"/",country,"-mls-cou-top-senders.json", sep=''))

        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, list("country", country_name))
        createJSON (data, paste(destdir,"/",country,"-mls-cou-static.json",sep=''))
    }
}

if ('companies' %in% reports){    
    companies = companiesNames(identities_db, startdate, enddate)
    createJSON(companies, paste(destdir,"/mls-companies.json",sep=''))

    for (company in companies){
        print (company)
        company_name = paste("'", company, "'", sep="")
        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("company", company_name)))
        data <- completePeriodIds(data, conf$granularity, conf)
        createJSON(data, paste(destdir,"/",company,"-mls-com-evolutionary.json", sep=''))

        top_senders = companyTopSenders (company, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir,"/",company,"-mls-com-top-senders.json", sep=''))

        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("company", company_name)))
        createJSON(data, paste(destdir,"/",company,"-mls-com-static.json", sep=''))
    }
}


if ('domains' %in% reports){
    domains = domainsNames(identities_db, startdate, enddate)
    createJSON(domains, paste(destdir,"/mls-domains.json",sep=''))

    for (domain in domains){
        print (domain)
        domain_name = paste("'", domain, "'", sep="")
        data = EvolMLSInfo(period, startdate, enddate, identities_db, rfield, (list("domain", domain_name)))
        data <- completePeriodIds(data, conf$granularity, conf)
        createJSON(data, paste(destdir,"/",domain,"-mls-dom-evolutionary.json", sep=''))

        top_senders = domainTopSenders (domain, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir,"/",domain,"-mls-dom-top-senders.json", sep=''))

        data = StaticMLSInfo(period, startdate, enddate, identities_db, rfield, (list("domain", domain_name)))
        createJSON(data, paste(destdir,"/",domain,"-mls-dom-static.json", sep=''))
    }
}

if ('people' %in% reports){
    people = GetListPeopleMLS(startdate, enddate)
    people = people$id
    limit = 100
    if (length(people)<limit) limit = length(people);
    people = people[1:limit]
    createJSON(people, paste(destdir,"/mls-people.json",sep=''))

    for (upeople_id in people){
        evol = GetEvolPeopleMLS(upeople_id, period, startdate, enddate)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        createJSON(evol, paste(destdir,"/people-",upeople_id,"-mls-evolutionary.json", sep=''))

        static <- GetStaticPeopleMLS(upeople_id, startdate, enddate)
        createJSON(static, paste(destdir,"/people-",upeople_id,"-mls-static.json", sep=''))
    }
}

##
# TIME TO ATTEND
## 

## Which quantiles we're interested in
# quantiles_spec = c(.99,.95,.5,.25)
## Yearly quantiles of time to attention (minutes)
ReportTimeToAttendMLS(destdir)

##
# DEMOGRAPHICS
## 
ReportDemographicsAgingMLS(conf$str_enddate, destdir)
ReportDemographicsBirthMLS(conf$str_enddate, destdir)

# Tops
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders(0, conf$startdate, conf$enddate,identities_db,c("-Bot"))
top_senders_data[['senders.last year']]<-top_senders(365, conf$startdate, conf$enddate,identities_db,c("-Bot"))
top_senders_data[['senders.last month']]<-top_senders(31, conf$startdate, conf$enddate,identities_db,c("-Bot"))

createJSON (top_senders_data, paste(destdir,"/mls-top.json",sep=''))

# People list
# query <- new ("Query", 
# 		sql = "select email_address as id, email_address, name, username from people")
# people <- run(query)
# createJSON (people, "data/json/mls-people.json")

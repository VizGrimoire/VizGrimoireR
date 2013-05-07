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

# dates
startdate <- conf$startdate
enddate <- conf$enddate

#
# GLOBAL
#
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 
rfield = reposField()

data <- mlsEvol(rfield, period, startdate, enddate, identities_db, conf$reports)
data <- completePeriodIds(data, conf$granularity, conf)
createJSON (data, paste(destdir,"/mls-evolutionary.json", sep=''))

static_data <- mlsStatic(rfield, startdate, enddate, conf$reports)
latest_activity7 <- lastActivity(7)
latest_activity30 <- lastActivity(30)
latest_activity90 <- lastActivity(90)
latest_activity365 <- lastActivity(365)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity365)
createJSON (static_data, paste(destdir,"/mls-static.json",sep=''))


if (conf$reports == 'repositories') {
    repos <- reposNames(rfield, startdate, enddate)
    createJSON (repos, "data/json/mls-lists.json")
    repos <- repos$mailing_list
    createJSON(repos, "data/json/mls-repos.json")	    
    
    print (repos)
    
    for (repo in repos) {    
        # Evol data
        data<-mlsEvolRepos(rfield, repo, period, startdate, enddate)
        data <- completePeriodIds(data, conf$granularity, conf)        
        listname_file = gsub("/","_",repo)
        
        # TODO: Multilist approach. We will obsolete it in future
        createJSON (data, paste(destdir,"/mls-",listname_file,"-evolutionary.json",sep=''))
        # Multirepos filename
        createJSON (data, paste(destdir,"/",listname_file,"-mls-evolutionary.json",sep=''))
        
        top_senders = repoTopSenders (repo, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir, "/",repo,"-mls-top-senders.json", sep=''))        
        
        # Static data
        data<-mlsStaticRepos(rfield, repo, startdate, enddate)
        # TODO: Multilist approach. We will obsolete it in future
    	createJSON (data, paste(destdir, "/",listname_file,"-static.json",sep=''))
    	# Multirepos filename
    	createJSON (data, paste(destdir, "/",listname_file,"-mls-static.json",sep=''))    
    }
}

if (conf$reports == 'countries') {
    countries <- countriesNames(identities_db, startdate, enddate) 
    createJSON (countries, paste(destdir, "/mls-countries.json",sep=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        data <- mlsEvolCountries(country, identities_db, period, startdate, enddate)
        data <- completePeriodIds(data, conf$granularity, conf)        
        createJSON (data, paste(destdir,"/",country,"-mls-evolutionary.json",sep=''))
        
        top_senders = countryTopSenders (country, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir,"/",country,"-mls-top-senders.json", sep=''))        
        
        data <- mlsStaticCountries(country, identities_db, startdate, enddate)
        createJSON (data, paste(destdir,"/",country,"-mls-static.json",sep=''))
    }
}

if (conf$reports == 'companies'){    
    companies = companiesNames(identities_db, startdate, enddate)
    createJSON(companies, paste(destdir,"/mls-companies.json",sep=''))
   
    for (company in companies){       
        print (company)
        sent.senders = mlsEvolCompanies(company, identities_db, period, startdate, enddate)
        # sent.senders <- completePeriod(sent.senders, nperiod, conf): Nice unixtime!!!
        sent.senders <- completePeriodIds(sent.senders, conf$granularity, conf)
        createJSON(sent.senders, paste(destdir,"/",company,"-mls-evolutionary.json", sep=''))

        top_senders = companyTopSenders (company, identities_db, startdate, enddate)
        createJSON(top_senders, paste(destdir,"/",company,"-mls-top-senders.json", sep=''))

        data = mlsStaticCompanies(company, identities_db, startdate, enddate)
        createJSON(data, paste(destdir,"/",company,"-mls-static.json", sep=''))
    }
}

# Demographics
d <- new ("Demographics","mls",6)
people <- Aging(d)
people$age <- as.Date(conf$str_enddate) - as.Date(people$firstdate)
people$age[people$age < 0 ] <- 0
aux <- data.frame(people["id"], people["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/mls-demographics-aging.json"), collapse=''))

newcomers <- Birth(d)
newcomers$age <- as.Date(conf$str_enddate) - as.Date(newcomers$firstdate)
newcomers$age[newcomers$age < 0 ] <- 0
aux <- data.frame(newcomers["id"], newcomers["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/mls-demographics-birth.json"), collapse=''))

# Tops
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders(0, conf$startdate, conf$enddate,identities_db,c("NULL"))
top_senders_data[['senders.last year']]<-top_senders(365, conf$startdate, conf$enddate,identities_db,c("NULL"))
top_senders_data[['senders.last month']]<-top_senders(31, conf$startdate, conf$enddate,identities_db,c("NULL"))

createJSON (top_senders_data, paste(destdir,"/mls-top.json",sep=''))

# People list
# query <- new ("Query", 
# 		sql = "select email_address as id, email_address, name, username from people")
# people <- run(query)
# createJSON (people, "data/json/mls-people.json")

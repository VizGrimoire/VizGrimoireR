#! /usr/bin/Rscript --vanilla

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
## Analyze and extract metrics data gathered by Bicho tool
## http://metricsgrimoire.github.com/Bicho
##
## This script analyzes data from a GitHub git repository
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##
## Usage:
## its-analysis-github.R -d dbname -u user -p passwd -i uids_dbname \
##   [-r repositories] --granularity days|weeks|months|years] \
##   --destination destdir
##
## (There are some more options, look at the source, Luke)
##
## Example:
##  LANG=en_US R_LIBS=rlib:$R_LIBS its-analysis-github.R -d proydb \
##  -u jgb -p XXX -i uiddb -r repositories --granularity weeks \
##  --destination destdir

library("vizgrimoire")
library(ISOweek)
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

##
## Returns the first and last dates in ITS repository
##
## Returns a vector with two strings: firstdate and lastdate
##
ITSDatesPeriod <- function () {
  q <- new ("Query", sql = "SELECT
          DATE(MIN(DATE)) as startdate,
          DATE(MAX(date)) as enddate
      FROM
          (SELECT submitted_on AS date FROM issues
           UNION ALL
           SELECT changed_on AS date FROM changes) AS dates")
  dates <- run(q)
  return (dates[1,])
}

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database,
	      user = conf$dbuser, password = conf$dbpassword)

period <- ITSDatesPeriod()
conf$startdate <- paste("'", as.character(period["startdate"]), "'", sep="")
conf$enddate <- paste("'", as.character(period["enddate"]), "'", sep="")
conf$str_startdate <- as.character(period["startdate"])
conf$str_enddate <- as.character(period["enddate"])
print(conf)
if (conf$granularity == 'years') { 
    period = 'year'
    nperiod = 365
} else if (conf$granularity == 'months') { 
    period = 'month'
    nperiod = 31
} else if (conf$granularity == 'weeks') { 
    period = 'week'
    nperiod = 7
} else if (conf$granularity == 'days'){ 
    period = 'day'
    nperiod = 1
} else {stop(paste("Incorrect period:",conf$granularity))}

conf$backend <- 'github'

## Closed condition for github
closed_condition <- "field='closed'"

## Dates
startdate <- conf$startdate
enddate <- conf$enddate
# Database with unique identities
identities_db <- conf$identities_db
# Reports
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]
# Destination directory
destdir <- conf$destination

#########
#EVOLUTIONARY DATA
#########

closed <- GetEvolClosed(closed_condition, period, startdate, enddate)
changed <- GetEvolChanged(period, startdate, enddate)
open <- GetEvolOpened(period, startdate, enddate)
repos <- GetEvolReposITS(period, startdate, enddate)

evol <- merge (open, closed, all = TRUE)
evol <- merge (evol, repos, all = TRUE)
evol <- merge (evol, changed, all = TRUE)

if ('repositories' %in% reports) {
    data = GetEvolReposITS(period, startdate, enddate)
    evol = merge(evol, data, all = TRUE)
}
if ('domains' %in% reports) {
    info_data_domains = GetEvolDomainsITS(period, startdate, enddate, identities_db)
    evol = merge(evol, info_data_domains, all = TRUE)
}

evol <- completePeriodIds(evol, conf$granularity, conf)
evol[is.na(evol)] <- 0
evol <- evol[order(evol$id),]
createJSON (evol, paste(c(destdir,"/its-evolutionary.json"), collapse=''))

## markov <- MarkovChain()
## createJSON (markov, paste(c(destdir,"/its-markov.json"), collapse=''))

##
## Data in snapshots
##

all_static_info <- GetStaticITS(closed_condition, startdate, enddate)
if ('domains' %in% reports) {
    info_com = GetStaticDomainsITS (startdate, enddate, identities_db)
    all_static_info = merge(all_static_info, info_com, all = TRUE)
}

closed_7 = GetDiffClosedDays(conf$enddate, 7, closed_condition)
closed_30 = GetDiffClosedDays(conf$enddate, 30, closed_condition)
closed_365 = GetDiffClosedDays(conf$enddate, 365, closed_condition)
opened_7 = GetDiffOpenedDays(conf$enddate, 7, closed_condition)
opened_30 = GetDiffOpenedDays(conf$enddate, 30, closed_condition)
opened_365 = GetDiffOpenedDays(conf$enddate, 365, closed_condition)
closers_7 = GetDiffClosersDays(conf$enddate, 7, closed_condition)
closers_30 = GetDiffClosersDays(conf$enddate, 30, closed_condition)
closers_365 = GetDiffClosersDays(conf$enddate, 365, closed_condition)
changers_7 = GetDiffChangersDays(conf$enddate, 7, closed_condition)
changers_30 = GetDiffChangersDays(conf$enddate, 30, closed_condition)
changers_365 = GetDiffChangersDays(conf$enddate, 365, closed_condition)

all_static_info = merge(all_static_info, closed_365)
all_static_info = merge(all_static_info, closed_30)
all_static_info = merge(all_static_info, closed_7)
all_static_info = merge(all_static_info, opened_365)
all_static_info = merge(all_static_info, opened_30)
all_static_info = merge(all_static_info, opened_7)
all_static_info = merge(all_static_info, closers_7)
all_static_info = merge(all_static_info, closers_30)
all_static_info = merge(all_static_info, closers_365)
all_static_info = merge(all_static_info, changers_7)
all_static_info = merge(all_static_info, changers_30)
all_static_info = merge(all_static_info, changers_365)

latest_activity7 = GetLastActivityITS(7, closed_condition)
latest_activity14 = GetLastActivityITS(14, closed_condition)
latest_activity30 = GetLastActivityITS(30, closed_condition)
latest_activity60 = GetLastActivityITS(60, closed_condition)
latest_activity90 = GetLastActivityITS(90, closed_condition)
latest_activity180 = GetLastActivityITS(180, closed_condition)
latest_activity365 = GetLastActivityITS(365, closed_condition)
latest_activity730 = GetLastActivityITS(730, closed_condition)
all_static_info = merge(all_static_info, latest_activity7)
all_static_info = merge(all_static_info, latest_activity14)
all_static_info = merge(all_static_info, latest_activity30)
all_static_info = merge(all_static_info, latest_activity60)
all_static_info = merge(all_static_info, latest_activity90)
all_static_info = merge(all_static_info, latest_activity180)
all_static_info = merge(all_static_info, latest_activity365)
all_static_info = merge(all_static_info, latest_activity730)
createJSON (all_static_info, paste(c(destdir,"/its-static.json"), collapse=''))

GetTopClosersSimple <- function(days = 0, startdate, enddate, identites_db) {
    
    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    q <- paste("SELECT up.id as id, up.identifier as closers,
                       count(distinct(c.id)) as closed
                FROM changes c, people_upeople pup, ",
               identities_db, ".upeople up
                WHERE pup.people_id = c.changed_by AND
                      pup.upeople_id = up.id AND
                      c.changed_on >= ", startdate, " AND
                      c.changed_on < ", enddate, " AND ",
                      closed_condition, " ", date_limit, "
                GROUP BY up.identifier
                ORDER BY closed desc
                LIMIT 10", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

# Top closers
top_closers_data <- list()
top_closers_data[['closers.']]<-GetTopClosersSimple(0, conf$startdate,
                                                    conf$enddate,identites_db)
top_closers_data[['closers.last year']]<-GetTopClosersSimple(365, conf$startdate,
                                                             conf$enddate,identites_db)
top_closers_data[['closers.last month']]<-GetTopClosersSimple(31, conf$startdate,
                                                              conf$enddate,identites_db)
top_closers_data[['closers.last week']]<-GetTopClosersSimple(7, conf$startdate,
                                                             conf$enddate,identites_db)

## # Top openers
## top_openers_data <- list()
## top_openers_data[['openers.']]<-GetTopOpeners(0, conf$startdate, conf$enddate,identites_db, c("-Bot"))
## top_openers_data[['openers.last year']]<-GetTopOpeners(365, conf$startdate, conf$enddate,identites_db, c("-Bot"))
## top_openers_data[['openers.last_month']]<-GetTopOpeners(31, conf$startdate, conf$enddate,identites_db, c("-Bot"))

all_top <- c(top_closers_data)
createJSON (all_top, paste(c(destdir,"/its-top.json"), collapse=''))

# People List for working in unique identites
# people_list <- its_people()
# createJSON (people_list, paste(c(destdir,"/its-people.json"), collapse=''))

# Repositories
if ('repositories' %in% reports) {	
	repos  <- GetReposNameITS()
	repos <- repos$name
	createJSON(repos, paste(c(destdir,"/its-repos.json"), collapse=''))
	
	for (repo in repos) {
		repo_name = paste(c("'", repo, "'"), collapse='')
		repo_aux = paste(c("", repo, ""), collapse='')
		repo_file = gsub("/","_",repo)
		print (repo_name)
		
		closed <- GetRepoEvolClosed(repo_name, closed_condition, period, startdate, enddate)
		changed <- GetRepoEvolChanged(repo_name, period, startdate, enddate)
		opened <- GetRepoEvolOpened(repo_name, period, startdate, enddate)        
		evol = merge(closed, changed, all = TRUE)
		evol = merge(evol, opened, all = TRUE)        
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
		createJSON(evol, paste(c(destdir,"/",repo_file,"-its-evolutionary.json"), collapse=''))
		
		static_info <- GetStaticRepoITS(repo_name, startdate, enddate)
		createJSON(static_info, paste(c(destdir,"/",repo_file,"-its-static.json"), collapse=''))
	}
}

# COMPANIES
if ('companies' %in% reports) {

    # companies <- its_companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), startdate, enddate, identities_db)
    companies  <- GetCompaniesNameITS(startdate, enddate, identities_db, c("-Bot", "-Individual", "-Unknown"))
    companies <- companies$name
    createJSON(companies, paste(c(destdir,"/its-companies.json"), collapse=''))
    
    for (company in companies){
        company_name = paste(c("'", company, "'"), collapse='')
        company_aux = paste(c("", company, ""), collapse='')
        print (company_name)

        closed <- GetCompanyEvolClosed(company_name, closed_condition, period, startdate, enddate, identities_db)
        changed <- GetCompanyEvolChanged(company_name, period, startdate, enddate, identities_db)
        opened <- GetCompanyEvolOpened(company_name, period, startdate, enddate, identities_db)        
        evol = merge(closed, changed, all = TRUE)
        evol = merge(evol, opened, all = TRUE)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]               
        createJSON(evol, paste(c(destdir,"/",company_aux,"-its-evolutionary.json"), collapse=''))

        static_info <- GetCompanyStaticITS(company_name, closed_condition, startdate, enddate, identities_db)
        createJSON(static_info, paste(c(destdir,"/",company_aux,"-its-static.json"), collapse=''))
		
        top_closers <- GetCompanyTopClosers(company_name, startdate, enddate, identities_db)
        createJSON(top_closers, paste(c(destdir,"/",company_aux,"-its-top-closers.json"), collapse=''))

    }
}

# COUNTRIES
if ('countries' %in% reports) {
    countries  <- GetCountriesNamesITS(conf$identities_db,conf$startdate, conf$enddate)
	countries <- countries$name
	createJSON(countries, paste(c(destdir,"/its-countries.json"), collapse=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        
        evol <- GetCountriesEvolITS(conf$identities_db, country, period, conf$startdate, conf$enddate)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
        createJSON (evol, paste(c(destdir,"/",country,"-its-evolutionary.json",sep=''), collapse=''))
        
        data <- GetCountriesStaticITS(conf$identities_db, country, conf$startdate, conf$enddate)
        createJSON (data, paste(c(destdir,"/",country,"-its-static.json",sep=''), collapse=''))
    }    
}

# People
if ('people' %in% reports) {
    people  <- GetPeopleListITS(conf$startdate, conf$enddate)
    people <- people$pid[1:30]
	createJSON(people, paste(c(destdir,"/its-people.json"), collapse=''))
    
    for (upeople_id in people) {
        evol <- GetPeopleEvolITS(upeople_id, period, conf$startdate, conf$enddate)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        createJSON (evol, paste(c(destdir,"/people-",upeople_id,"-its-evolutionary.json",sep=''), collapse=''))
        
        data <- GetPeopleStaticITS(upeople_id, conf$startdate, conf$enddate)
        createJSON (data, paste(c(destdir,"/people-",upeople_id,"-its-static.json",sep=''), collapse=''))
    }    
}
    
# Time to Close: Other backends not yet supported
if (conf$backend == 'bugzilla' || 
    conf$backend == 'allura' || 
    conf$backend == 'jira' ||
    conf$backend == 'launchpad') { 
    ## Quantiles
    ## Which quantiles we're interested in
    quantiles_spec = c(.99,.95,.5,.25)
    
    ## Closed tickets: time ticket was open, first closed, time-to-first-close
    closed <- new ("ITSTicketsTimes")
    
    ## Yearly quantiles of time to fix (minutes)
    events.tofix <- new ("TimedEvents",
                         closed$open, closed$tofix %/% 60)
    quantiles <- QuantilizeYears (events.tofix, quantiles_spec)
    JSON(quantiles, paste(c(destdir,'/its-quantiles-year-time_to_fix_min.json'), collapse=''))
    
    ## Monthly quantiles of time to fix (hours)
    events.tofix.hours <- new ("TimedEvents",
                               closed$open, closed$tofix %/% 3600)
    quantiles.month <- QuantilizeMonths (events.tofix.hours, quantiles_spec)
    JSON(quantiles.month, paste(c(destdir,'/its-quantiles-month-time_to_fix_hour.json'), collapse=''))
    
    ## Changed tickets: time ticket was attended, last move
    changed <- new ("ITSTicketsChangesTimes")
    ## Yearly quantiles of time to attention (minutes)
    events.toatt <- new ("TimedEvents",
                         changed$open, changed$toattention %/% 60)
    quantiles <- QuantilizeYears (events.tofix, quantiles_spec)
    JSON(quantiles, paste(c(destdir,'/its-quantiles-year-time_to_attention_min.json'), collapse=''))
}

# Demographics
d <- new ("Demographics","its",6)
people <- Aging(d)
people$age <- as.Date(conf$str_enddate) - as.Date(people$firstdate)
people$age[people$age < 0 ] <- 0
aux <- data.frame(people["id"], people["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/its-demographics-aging.json"), collapse=''))

newcomers <- Birth(d)
newcomers$age <- as.Date(conf$str_enddate) - as.Date(newcomers$firstdate)
newcomers$age[newcomers$age < 0 ] <- 0
aux <- data.frame(newcomers["id"], newcomers["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/its-demographics-birth.json"), collapse=''))

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
## http://vizgrimoire.bitergia.org/
##
## Analyze and extract metrics data gathered by CVSAnalY tool
## http://metricsgrimoire.github.com/CVSAnalY
##
## This script analyzes data from a GitHub git repository
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
## Usage:
## scm-analysis-github.R -d dbname -u user -p passwd -i uids_dbname \
##   [-r repositories] --granularity days|weeks|months|years] \
##   --destination destdir
##
## (There are some more options, look at the source, Luke)
##
## Example:
##  LANG=en_US R_LIBS=rlib:$R_LIBS scm-analysis-github.R -d proydb \
##  -u jgb -p XXX -i uiddb -r repositories --granularity weeks \
##  --destination destdir

library("vizgrimoire")
library(ISOweek)
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

##
## Returns the first and last dates in SCM repository
##
## Returns a vector with two strings: firstdate and lastdate
##
SCMDatesPeriod <- function () {
  q <- new ("Query",
            sql = "SELECT DATE(MIN(date)) as startdate,
                     DATE(MAX(date)) as enddate FROM scmlog")
  dates <- run(q)
  return (dates[1,])
}


conf <- ConfFromOptParse()
SetDBChannel (database = conf$database,
	      user = conf$dbuser, password = conf$dbpassword)

period <- SCMDatesPeriod()
conf$startdate <- paste("'", as.character(period["startdate"]), "'", sep="")
conf$enddate <- paste("'", as.character(period["enddate"]), "'", sep="")
#conf$startdate <- as.character(period["startdate"])
#conf$enddate <- as.character(period["enddate"])
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


# destination directory
destdir <- conf$destination

# multireport
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]

#########
#EVOLUTIONARY DATA
#########

evol_data <- GetSCMEvolutionaryData(period, conf$startdate, conf$enddate,
                                    conf$identities_db)
domains <- EvolDomains(period, conf$startdate, conf$enddate)
evol_data = merge(evol_data, domains, all = TRUE)

evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
evol_data <- evol_data[order(evol_data$id), ]
evol_data[is.na(evol_data)] <- 0

createJSON (evol_data, paste(destdir,"/scm-evolutionary.json", sep=''))

#########
#STATIC DATA
#########

static_data = GetSCMStaticData(period, conf$startdate, conf$enddate, conf$identities_db)
static_url <- StaticURL()
diffcommits <- GetDiffCommitsDays(period, conf$enddate, 365)
latest_activity7 = last_activity(7)
latest_activity14 = last_activity(14)
latest_activity30 = last_activity(30)
latest_activity60 = last_activity(60)
latest_activity90 = last_activity(90)
latest_activity180 = last_activity(180)
latest_activity365 = last_activity(365)
latest_activity730 = last_activity(730)

diffcommits_365 = GetDiffCommitsDays(period, conf$enddate, 365)
diffauthors_365 = GetDiffAuthorsDays(period, conf$enddate, conf$identities_db, 365)
diff_files_365 = GetDiffFilesDays(period, conf$enddate, conf$identities_db, 365)
diff_lines_365 = GetDiffLinesDays(period, conf$enddate, conf$identities_db, 365)

diffcommits_30 = GetDiffCommitsDays(period, conf$enddate, 30)
diffauthors_30 = GetDiffAuthorsDays(period, conf$enddate, conf$identities_db, 30)
diff_files_30 = GetDiffFilesDays(period, conf$enddate, conf$identities_db, 30)
diff_lines_30 = GetDiffLinesDays(period, conf$enddate, conf$identities_db, 30)

diffcommits_7 = GetDiffCommitsDays(period, conf$enddate, 7)
diffauthors_7 = GetDiffAuthorsDays(period, conf$enddate, conf$identities_db, 7)
diff_files_7 = GetDiffFilesDays(period, conf$enddate, conf$identities_db, 7)
diff_lines_7 = GetDiffLinesDays(period, conf$enddate, conf$identities_db, 7)

community_structure = GetCodeCommunityStructure(period, conf$startdate, conf$enddate, conf$identities_db)

static_data_domains = evol_info_data_domains (conf$startdate, conf$enddate)
static_data = merge(static_data, static_data_domains)

static_data = merge(static_data, static_url)
static_data = merge(static_data, diffcommits)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity14)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity60)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity180)
static_data = merge(static_data, latest_activity365)
static_data = merge(static_data, latest_activity730)
static_data = merge(static_data, community_structure)
static_data = merge(static_data, diffcommits_365)
static_data = merge(static_data, diffcommits_30)
static_data = merge(static_data, diffcommits_7)
static_data = merge(static_data, diffauthors_365)
static_data = merge(static_data, diffauthors_30)
static_data = merge(static_data, diffauthors_7)
static_data = merge(static_data, diff_files_365)
static_data = merge(static_data, diff_files_30)
static_data = merge(static_data, diff_files_7)
static_data = merge(static_data, diff_lines_365)
static_data = merge(static_data, diff_lines_30)
static_data = merge(static_data, diff_lines_7)

createJSON (static_data, paste(destdir,"/scm-static.json", sep=''))


# Top authors

top_authors_data <- list()
top_authors_data[['authors.']] <- top_authors(conf$startdate, conf$enddate)
createJSON (top_authors_data, paste(destdir,"/scm-top.json", sep=''))

# Top files
top_files_modified_data = top_files_modified()

reports <- "repositories"
if ('repositories' %in% reports) {
    repos  <- repos_name(conf$startdate, conf$enddate)
    repos <- repos$name
    createJSON(repos, paste(destdir,"/scm-repos.json", sep=''))
	
    for (repo in repos) {
        repo_name = paste("'", repo, "'", sep='')
        repo_aux = paste("", repo, "", sep='')
        print (repo_name)
        
        ###########
        #EVOLUTIONARY DATA
        ###########
        #1- Retrieving data
  
        evol_data <- GetSCMEvolutionaryData(period,
                                            conf$startdate, conf$enddate,
                                            conf$identities_db,
                                            list ("repository", repo_name))
        evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
        evol_data <- evol_data[order(evol_data$id), ]
        evol_data[is.na(evol_data)] <- 0
        
        #3- Creating JSON
        createJSON(evol_data, paste(destdir, "/",repo_aux,"-scm-evolutionary.json", sep=''))
		
        ##########
        #STATIC DATA
        ##########
        # 1- Retrieving information
        static_data <- GetSCMStaticData(period, conf$startdate, conf$enddate,
                                        conf$identities_db,
                                        list ("repository", repo_name))

        #3- Creating JSON
        #static_info <- evol_info_data_repo(repo_name, period, conf$startdate, conf$enddate)
        createJSON(static_data, paste(destdir, "/",repo_aux,"-scm-static.json", sep=''))		
    }		
}

if ('countries' %in% reports) {
    countries  <- scm_countries_names(conf$identities_db,conf$startdate, conf$enddate)
    countries <- countries$name
    createJSON(countries, paste(destdir,"/scm-countries.json", sep=''))
	
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        country_name = paste("'", country, "'", sep='')
        
        evol_data <- EvolCommits(period, conf$startdate, conf$enddate, conf$identities_db, country=country_name)        
        evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
        evol_data <- evol_data[order(evol_data$id), ]
        evol_data[is.na(evol_data)] <- 0
        
        createJSON (evol_data, paste(destdir, "/",country,"-scm-evolutionary.json",sep=''))
        
        data <- scm_countries_static(conf$identities_db, country, conf$startdate, conf$enddate)
        createJSON (data, paste(destdir, "/",country,"-scm-static.json",sep=''))        
    }
}

if ('people' %in% reports) {
    print ('Starting people analysis')
    people  <- GetPeopleListSCM(conf$startdate, conf$enddate)
    createJSON(people, paste(destdir,"/scm-people.json", sep=''))
	
    for (upeople_id in people$id) {
        evol_data <- GetEvolPeopleSCM(upeople_id, period, 
                conf$startdate, conf$enddate)
        evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
        evol_data[is.na(evol_data)] <- 0
        createJSON (evol_data, paste(destdir,"/people-",
                        upeople_id,"-scm-evolutionary.json", sep=''))
        static_data <- GetStaticPeopleSCM(upeople_id, 
                conf$startdate, conf$enddate)
        createJSON (static_data, paste(destdir,"/people-",
                        upeople_id,"-scm-static.json", sep=''))        
    }        
}


# Demographics
d <- new ("Demographics","scm",6)
people <- Aging(d)
people$age <- as.Date(conf$str_enddate) - as.Date(people$firstdate)
people$age[people$age < 0 ] <- 0
aux <- data.frame(people["id"], people["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/scm-demographics-aging.json"), collapse=''))

newcomers <- Birth(d)
newcomers$age <- as.Date(conf$str_enddate) - as.Date(newcomers$firstdate)
newcomers$age[newcomers$age < 0 ] <- 0
aux <- data.frame(newcomers["id"], newcomers["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/scm-demographics-birth.json"), collapse=''))

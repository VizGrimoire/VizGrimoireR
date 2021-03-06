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
##   Alvaro del Castillo <acs@bitergia.com>
##   Daniel Izquierdo-Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -d dbname < its-analysis.R
## or
##  R CMD BATCH scm-analysis.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
## conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
##                            user = "root", password = NULL,
##                            host = "127.0.0.1", port = 3308)
## SetDBChannel (database = conf$database,
##               user = conf$user, password = conf$password,
##               host = conf$host, port = conf$port)
# conf <- ConfFromParameters(dbschema = "kdevelop_bicho", user = "jgb", password = "XXX")

conf <- ConfFromOptParse('its')
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)

# backends
if (conf$backend == 'allura'){
    closed_condition <- "new_value='CLOSED'"
}
if (conf$backend == 'bugzilla'){
    closed_condition <- "(new_value='RESOLVED' OR new_value='CLOSED')"
}
if (conf$backend == 'github'){
    closed_condition <- "field='closed'"
}
if (conf$backend == 'jira'){
    closed_condition <- "new_value='CLOSED'"
}
if (conf$backend == 'launchpad'){
    closed_condition <- "(new_value='Fix Released' or new_value='Invalid' or new_value='Expired' or new_value='Won''t Fix')"
}

# period of time
if (conf$granularity == 'months'){
   period = 'month'
}
if (conf$granularity == 'weeks'){
   period = 'week'
}

# dates
startdate <- conf$startdate
enddate <- conf$enddate

# database with unique identities
identities_db <- conf$identities_db
>>>>>>> unique-ids

closed <- evol_closed(closed_condition, period, startdate, enddate)
changed <- evol_changed(period, startdate, enddate)
open <- evol_opened(period, startdate, enddate)
repos <- its_evol_repositories(period, startdate, enddate)

issues <- merge (open, closed, all = TRUE)
issues <- merge (issues, changed, all = TRUE)
issues <- merge (issues, repos, all = TRUE)

if (conf$reports == 'companies') {
    info_data_companies = its_evol_companies (period, startdate, enddate, identities_db)
    issues = merge(issues, info_data_companies, all = TRUE)
}
issues[is.na(issues)] <- 0
createJSON (issues, "data/json/its-evolutionary.json")

all_static_info <- its_static_info(closed_condition, startdate, enddate)
if (conf$reports == 'companies') {
    info_com = its_static_companies (startdate, enddate, identities_db)
    all_static_info = merge(all_static_info, info_com, all = TRUE)
}
createJSON (all_static_info, "data/json/its-static.json")



# Top closers
top_closers_data <- list()
top_closers_data[['closers.']]<-top_closers()
top_closers_data[['closers.last year']]<-top_closers(365)
top_closers_data[['closers.last month']]<-top_closers(31)

createJSON (top_closers_data, "data/json/its-top.json")

# People List for working in unique identites
people_list <- its_people()
createJSON (people_list, "data/json/its-people.json")

# Repositories
if (conf$reports == 'repositories') {	
	repos  <- its_repos_name()
	repos <- repos$name
	createJSON(repos, "data/json/its-repos.json")
	
	for (repo in repos) {
		repo_name = paste(c("'", repo, "'"), collapse='')
		repo_aux = paste(c("", repo, ""), collapse='')
		repo_file = gsub("/","_",repo)
		print (repo_name)
		
		# EVOLUTION INFO
		closed <- repo_evol_closed(repo_name, closed_condition, period, startdate, enddate)
		changed <- repo_evol_changed(repo_name, period, startdate, enddate)
		opened <- repo_evol_opened(repo_name, period, startdate, enddate)                
		agg_data = merge(closed, changed, all = TRUE)
		agg_data = merge(agg_data, opened, all = TRUE)	
		agg_data[is.na(agg_data)] <- 0
		createJSON(agg_data, paste(c("data/json/",repo_file,"-its-evolutionary.json"), collapse=''))
		
		# STATIC INFO
		static_info <- its_static_info_repo(repo_name)
		createJSON(static_info, paste(c("data/json/",repo_file,"-its-static.json"), collapse=''))		
	}
}

# Companies
if (conf$reports == 'companies') {
    companies  <- its_companies_name(startdate, enddate, identities_db)
    companies <- companies$name
    createJSON(companies, "data/json/its-companies.json")
    
    for (company in companies){
        company_name = paste(c("'", company, "'"), collapse='')
        company_aux = paste(c("", company, ""), collapse='')
        print (company_name)
        closed <- its_company_evol_closed(company_name, closed_condition, period, startdate, enddate, identities_db)
        changed <- its_company_evol_changed(company_name, period, startdate, enddate, identities_db)
        opened <- its_company_evol_opened(company_name, period, startdate, enddate, identities_db)
        agg_data = merge(closed, changed, all = TRUE)
        agg_data = merge(agg_data, opened, all = TRUE)
        createJSON(agg_data, paste(c("data/json/",company_aux,"-its-evolutionary.json"), collapse=''))

        print ("static info")
        static_info <- its_company_static_info(company_name, startdate, enddate, identities_db)
        createJSON(static_info, paste(c("data/json/",company_aux,"-its-static.json"), collapse=''))
		
        print ("top closers")
        top_closers <- its_company_top_closers(company_name, startdate, enddate, identities_db)
        createJSON(top_closers, paste(c("data/json/",company_aux,"-its-top-closers.json"), collapse=''))

    }
}

# Quantiles

## Which quantiles we're interested in
quantiles_spec = c(.99,.95,.5,.25)

## Closed tickets: time ticket was open, first closed, time-to-first-close
closed <- new ("ITSTicketsTimes")
## Yearly quantiles of time to fix (minutes)
events.tofix <- new ("TimedEvents",
                     closed$open, closed$tofix %/% 60)
quantiles <- QuantilizeYears (events.tofix, quantiles_spec)
JSON(quantiles, 'data/json/its-quantiles-year-time_to_fix_min.json')

## Monthly quantiles of time to fix (hours)
events.tofix.hours <- new ("TimedEvents",
                           closed$open, closed$tofix %/% 3600)
quantiles.month <- QuantilizeMonths (events.tofix.hours, quantiles_spec)
JSON(quantiles.month, 'data/json/its-quantiles-month-time_to_fix_hour.json')

## Changed tickets: time ticket was attended, last move
changed <- new ("ITSTicketsChangesTimes")
## Yearly quantiles of time to attention (minutes)
events.toatt <- new ("TimedEvents",
                     changed$open, changed$toattention %/% 60)
quantiles <- QuantilizeYears (events.tofix, quantiles_spec)
JSON(quantiles, 'data/json/its-quantiles-year-time_to_attention_min.json')

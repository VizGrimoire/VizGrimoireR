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
##  R CMD BATCH its-analysis.R
##

library("vizgrimoire")
library("ISOweek")
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

# period of time
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


# backends
if (conf$backend == 'allura'){
    closed_condition <- "new_value='CLOSED'"
}
if (conf$backend == 'bugzilla'){
    closed_condition <- "(new_value='RESOLVED' OR new_value='CLOSED')"
    reopened_condition <- "new_value='NEW'"
    name_log_table <- 'issues_log_bugzilla'
    statuses = c("NEW", "ASSIGNED")
    #Pretty specific states in Red Hat's Bugzilla
    statuses = c("ASSIGNED", "CLOSED", "MODIFIED", "NEW", "ON_DEV", "ON_QA", "POST", "RELEASE_PENDING", "VERIFIED")
}
if (conf$backend == 'github'){
    closed_condition <- "field='closed'"
}
if (conf$backend == 'jira'){
    closed_condition <- "new_value='CLOSED'"
    reopened_condition <- "new_value='Reopened'"
    #new_condition <- "status='Open'"
    #reopened_condition <- "status='Reopened'"
    open_status <- 'Open'
    reopened_status <- 'Reopened'
    name_log_table <- 'issues_log_jira'
}
if (conf$backend == 'launchpad'){
    #closed_condition <- "(new_value='Fix Released' or new_value='Invalid' or new_value='Expired' or new_value='Won''t Fix')"
    closed_condition <- "(new_value='Fix Committed')"
}
if (conf$backend == 'redmine'){
    statuses = c("New", "Verified", "Need More Info", "In Progress", "Feedback",
                 "Need Review", "Testing", "Pending Backport", "Pending Upstream",
                 "Resolved", "Closed", "Rejected", "Won\\'t Fix", "Can\\'t reproduce",
                 "Duplicate")
    closed_condition <- paste("(new_value='Resolved' OR new_value='Closed' OR new_value='Rejected'",
                              " OR new_value='Won\\'t Fix' OR new_value='Can\\'t reproduce' OR new_value='Duplicate')")
    reopened_condition <- "new_value='Reopened'" # FIXME: fake condition
    name_log_table <- 'issues_log_redmine'
}

# dates
startdate <- conf$startdate
enddate <- conf$enddate

# database with unique identities
identities_db <- conf$identities_db

# multireport
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]

# destination directory
destdir <- conf$destination

options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

closed <- EvolIssuesClosed(period, startdate, enddate, identities_db, list(NA, NA), closed_condition)
changed <- EvolIssuesChanged(period, startdate, enddate, identities_db, list(NA, NA))
open <- EvolIssuesOpened(period, startdate, enddate, identities_db, list(NA, NA))
repos <- EvolIssuesRepositories(period, startdate, enddate, identities_db, list(NA, NA))

evol <- merge (open, closed, all = TRUE)
evol <- merge (evol, repos, all = TRUE)
evol <- merge (evol, changed, all = TRUE)


markov <- MarkovChain()
createJSON (markov, paste(c(destdir,"/its-markov.json"), collapse=''))



#for (status in statuses)
#{
    #Evolution of the backlog
    #tickets_status <- GetEvolBacklogTickets(period, startdate, enddate, status, name_log_table)
    #colnames(tickets_status)[2] <- status

    #Issues per status
    #current_status <- GetCurrentStatus(period, startdate, enddate, identities_db, status)
    
    #Merging data
    #if (nrow(current_status)>0){
    #    evol <- merge(evol, current_status, all=TRUE)
    #}
    #evol <- merge (evol, tickets_status, all = TRUE)
#}



if ('companies' %in% reports) {
    info_data_companies = EvolIssuesCompanies(period, startdate, enddate, identities_db)
    evol = merge(evol, info_data_companies, all = TRUE)
}
if ('countries' %in% reports) {
    info_data_countries = EvolIssuesCountries(period, startdate, enddate, identities_db)
    evol = merge(evol, info_data_countries, all = TRUE)
}
if ('repositories' %in% reports) {
    data = EvolIssuesRepositories(period, startdate, enddate, identities_db)
    evol = merge(evol, data, all = TRUE)
}
if ('domains' %in% reports) {
    info_data_domains = EvolIssuesDomains(period, startdate, enddate, identities_db)
    evol = merge(evol, info_data_domains, all = TRUE)
}

evol <- completePeriodIds(evol, conf$granularity, conf)
evol[is.na(evol)] <- 0
evol <- evol[order(evol$id),]
createJSON (evol, paste(c(destdir,"/its-evolutionary.json"), collapse=''))

#Missing some metrics here. TBD
closed <- AggIssuesClosed(period, startdate, enddate, identities_db, list(NA, NA), closed_condition)
changed <- AggIssuesChanged(period, startdate, enddate, identities_db, list(NA, NA))
open <- AggIssuesOpened(period, startdate, enddate, identities_db, list(NA, NA))

all_static_info = merge(closed, changed)
all_static_info = merge(all_static_info, open)


if ('companies' %in% reports) {
    info_com = AggIssuesCompanies(period, startdate, enddate, identities_db)
    all_static_info = merge(all_static_info, info_com, all = TRUE)
}
if ('countries' %in% reports) {
    info_com = AggIssuesCountries(period, startdate, enddate, identities_db)
    all_static_info = merge(all_static_info, info_com, all = TRUE)
}
if ('domains' %in% reports) {
    info_com = AggIssuesDomains(period, startdate, enddate, identities_db)
    all_static_info = merge(all_static_info, info_com, all = TRUE)
}

closed_7 = GetDiffClosedDays(period, identities_db, conf$enddate, 7, list(NA, NA), closed_condition)
closed_30 = GetDiffClosedDays(period, identities_db, conf$enddate, 30, list(NA, NA), closed_condition)
closed_365 = GetDiffClosedDays(period, identities_db, conf$enddate, 365, list(NA, NA), closed_condition)

opened_7 = GetDiffOpenedDays(period, identities_db, conf$enddate, 7, list(NA, NA))
opened_30 = GetDiffOpenedDays(period, identities_db, conf$enddate, 30, list(NA, NA))
opened_365 = GetDiffOpenedDays(period, identities_db, conf$enddate, 365, list(NA, NA))
closers_7 = GetDiffClosersDays(period, identities_db, conf$enddate, 7, list(NA, NA), closed_condition)
closers_30 = GetDiffClosersDays(period, identities_db, conf$enddate, 30, list(NA, NA), closed_condition)
closers_365 = GetDiffClosersDays(period, identities_db, conf$enddate, 365, list(NA, NA), closed_condition)
changers_7 = GetDiffChangersDays(period, identities_db, conf$enddate, 7, list(NA, NA))
changers_30 = GetDiffChangersDays(period, identities_db, conf$enddate, 30, list(NA, NA))
changers_365 = GetDiffChangersDays(period, identities_db, conf$enddate, 365, list(NA, NA))


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

# Top closers
top_closers_data <- list()
top_closers_data[['closers.']]<-GetTopClosers(0, conf$startdate, conf$enddate,identites_db, c("-Bot"))
top_closers_data[['closers.last year']]<-GetTopClosers(365, conf$startdate, conf$enddate,identites_db, c("-Bot"))
top_closers_data[['closers.last month']]<-GetTopClosers(31, conf$startdate, conf$enddate,identites_db, c("-Bot"))

# Top openers
top_openers_data <- list()
top_openers_data[['openers.']]<-GetTopOpeners(0, conf$startdate, conf$enddate,identites_db, c("-Bot"))
top_openers_data[['openers.last year']]<-GetTopOpeners(365, conf$startdate, conf$enddate,identites_db, c("-Bot"))
top_openers_data[['openers.last_month']]<-GetTopOpeners(31, conf$startdate, conf$enddate,identites_db, c("-Bot"))



all_top <- c(top_closers_data, top_openers_data)
createJSON (all_top, paste(c(destdir,"/its-top.json"), collapse=''))

# People List for working in unique identites
# people_list <- its_people()
# createJSON (people_list, paste(c(destdir,"/its-people.json"), collapse=''))

# Repositories
if ('repositories' %in% reports) {	
    repos  <- GetReposNameITS(startdate, enddate)
    repos <- repos$name
    createJSON(repos, paste(c(destdir,"/its-repos.json"), collapse=''))
	
    for (repo in repos) {
        repo_name = paste(c("'", repo, "'"), collapse='')
        repo_aux = paste(c("", repo, ""), collapse='')
        repo_file = gsub("/","_",repo)
        print (repo_name)

        closed <- EvolIssuesClosed(period, startdate, enddate, identities_db, list('repository', repo_name), closed_condition)
        changed <- EvolIssuesChanged(period, startdate, enddate, identities_db, list('repository', repo_name))
        open <- EvolIssuesOpened(period, startdate, enddate, identities_db, list('repository', repo_name))
		
        evol = merge(closed, changed, all = TRUE)
        evol = merge(evol, open, all = TRUE)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
        createJSON(evol, paste(c(destdir,"/",repo_file,"-its-rep-evolutionary.json"), collapse=''))

        closed <- AggIssuesClosed(period, startdate, enddate, identities_db, list('repository', repo_name), closed_condition)
        changed <- AggIssuesChanged(period, startdate, enddate, identities_db, list('repository', repo_name))
        open <- AggIssuesOpened(period, startdate, enddate, identities_db, list('repository', repo_name))
        static_info = merge(closed, changed)
        static_info = merge(static_info, open)	
        createJSON(static_info, paste(c(destdir,"/",repo_file,"-its-rep-static.json"), collapse=''))
	}
}

# COMPANIES
if ('companies' %in% reports) {

    # companies <- its_companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), startdate, enddate, identities_db)
    companies  <- GetCompaniesNameITS(startdate, enddate, identities_db, closed_condition, c("-Bot", "-Individual", "-Unknown"))
    companies <- companies$name
    createJSON(companies, paste(c(destdir,"/its-companies.json"), collapse=''))

    for (company in companies){
        company_name = paste(c("'", company, "'"), collapse='')
        company_aux = paste(c("", company, ""), collapse='')
        print (company_name)

        closed <- EvolIssuesClosed(period, startdate, enddate, identities_db, list('company', company_name), closed_condition)
        changed <- EvolIssuesChanged(period, startdate, enddate, identities_db, list('company', company_name))
        open <- EvolIssuesOpened(period, startdate, enddate, identities_db, list('company', company_name))

        evol = merge(closed, changed, all = TRUE)
        evol = merge(evol, open, all = TRUE)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
        createJSON(evol, paste(c(destdir,"/",company_aux,"-its-com-evolutionary.json"), collapse=''))

        closed <- AggIssuesClosed(period, startdate, enddate, identities_db, list('company', company_name), closed_condition)
        changed <- AggIssuesChanged(period, startdate, enddate, identities_db, list('company', company_name))
        open <- AggIssuesOpened(period, startdate, enddate, identities_db, list('company', company_name))
        static_info = merge(closed, changed)
        static_info = merge(static_info, open)
        createJSON(static_info, paste(c(destdir,"/",company_aux,"-its-com-static.json"), collapse=''))
		
        top_closers <- GetCompanyTopClosers(company_name, startdate, enddate, identities_db)
        createJSON(top_closers, paste(c(destdir,"/",company_aux,"-its-com-top-closers.json"), collapse=''))

    }
}

# COUNTRIES
if ('countries' %in% reports) {
    countries  <- GetCountriesNamesITS(conf$startdate, conf$enddate, conf$identities_db, closed_condition)
	countries <- countries$name
	createJSON(countries, paste(c(destdir,"/its-countries.json"), collapse=''))

    for (country in countries) {
        if (is.na(country)) next
        print (country)

        country_name = paste("'", country, "'", sep="")
        closed <- EvolIssuesClosed(period, startdate, enddate, identities_db, list('country', country_name), closed_condition)
        changed <- EvolIssuesChanged(period, startdate, enddate, identities_db, list('country', country_name))
        open <- EvolIssuesOpened(period, startdate, enddate, identities_db, list('country', country_name))
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
        createJSON (evol, paste(c(destdir,"/",country,"-its-cou-evolutionary.json",sep=''), collapse=''))


        closed <- AggIssuesClosed(period, startdate, enddate, identities_db, list('country', country_name), closed_condition)
        changed <- AggIssuesChanged(period, startdate, enddate, identities_db, list('country', country_name))
        open <- AggIssuesOpened(period, startdate, enddate, identities_db, list('country', country_name))
        data = merge(closed, changed)
        data = merge(data, open)
        createJSON (data, paste(c(destdir,"/",country,"-its-cou-static.json",sep=''), collapse=''))
    }
}
# Domains
if ('domains' %in% reports) {
    domains <- GetDomainsNameITS(startdate, enddate, identities_db, closed_condition, c("-Bot"))
    domains <- domains$name
    createJSON(domains, paste(c(destdir,"/its-domains.json"), collapse=''))

    for (domain in domains){
        domain_name = paste(c("'", domain, "'"), collapse='')
        domain_aux = paste(c("", domain, ""), collapse='')
        print (domain_name)

        closed <- EvolIssuesClosed(period, startdate, enddate, identities_db, list('domain', domain_name), closed_condition)
        changed <- EvolIssuesChanged(period, startdate, enddate, identities_db, list('domain', domain_name))
        open <- EvolIssuesOpened(period, startdate, enddate, identities_db, list('domain', domain_name))
        evol = merge(closed, changed, all = TRUE)
        evol = merge(evol, open, all = TRUE)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        evol <- evol[order(evol$id),]
        createJSON(evol, paste(c(destdir,"/",domain_aux,"-its-dom-evolutionary.json"), collapse=''))

        closed <- AggIssuesClosed(period, startdate, enddate, identities_db, list('domain', domain_name), closed_condition)
        changed <- AggIssuesChanged(period, startdate, enddate, identities_db, list('domain', domain_name))
        open <- AggIssuesOpened(period, startdate, enddate, identities_db, list('domain', domain_name))
        static_info = merge(closed, changed)
        static_info = merge(static_info, open)
        createJSON(static_info, paste(c(destdir,"/",domain_aux,"-its-dom-static.json"), collapse=''))

        top_closers <- GetDomainTopClosers(domain_name, startdate, enddate, identities_db)
        createJSON(top_closers, paste(c(destdir,"/",domain_aux,"-its-dom-top-closers.json"), collapse=''))
    }
}
# People
if ('people' %in% reports) {
    people  <- GetPeopleListITS(conf$startdate, conf$enddate)
    people = people$pid
    limit = 30
    if (length(people)<limit) limit = length(people);
    people = people[1:limit]
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

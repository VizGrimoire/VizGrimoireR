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
## Analyze and extract metrics data gathered by Bicho tool
## http://metricsgrimoire.github.com/CVSAnalY
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -d dbname < scm-analysis.R
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
## conf <- ConfFromParameters(dbschema = "kdevelop", user = "jgb", password = "XXX")
conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)


sql_res = 1 # 1 day resolution  SQL
period = conf$granularity
if (period == 'months'){
       sql_period = 'month'
}
if (period == 'weeks'){
       sql_period='week'
}
if (period == 'years'){
    sql_period='year'
}

#Commits per month
# commits <- evol_commits(nperiod, conf$startdate, conf$enddate)
commits <- evol_commits(sql_res, conf$startdate, conf$enddate)
print(commits)
data_commits <- completePeriod2(commits, period, 
        conf$str_startdate, conf$str_enddate)

#Committers per month
committers <- evol_committers(sql_res, conf$startdate, conf$enddate)
data_committers <- completePeriod2(committers, period, 
        conf$str_startdate, conf$str_enddate)

# Authors per month
authors <- evol_authors(sql_res, conf$startdate, conf$enddate)
data_authors <- completePeriod2(authors, period, 
        conf$str_startdate, conf$str_enddate)

#Files per month
files <- evol_files(sql_res, conf$startdate, conf$enddate)
data_files <- completePeriod2(files, period, 
        conf$str_startdate, conf$str_enddate)

#Lines: two metrics. process each one isolate and merge
lines <- evol_lines(sql_res, conf$startdate, conf$enddate)
data_lines<- completePeriodMulti(lines, c('added_lines','removed_lines'),period, 
        conf$str_startdate, conf$str_enddate)

#lines_added <- data.frame(id=lines$id,added_lines=lines$added_lines)
#lines_added <- completePeriod2(lines_added, period, 
#        conf$str_startdate, conf$str_enddate)
#lines_removed <- data.frame(id=lines$id,removed_lines=lines$removed_lines)
#lines_removed <- completePeriod2(lines_removed, period, 
#        conf$str_startdate, conf$str_enddate)
#data_lines <- merge(lines_added,lines_removed, all = TRUE)

#Branches per month
branches <- evol_branches(sql_res, conf$startdate, conf$enddate)
data_branches <- completePeriod2(branches, period, 
        conf$str_startdate, conf$str_enddate)

#Repositories per month
repositories <- evol_repositories(sql_res, conf$startdate, conf$enddate)
data_repositories <- completePeriod2(repositories, period, 
        conf$str_startdate, conf$str_enddate)

if (conf$reports == 'companies') { 
    companies <- evol_companies(sql_res, conf$startdate, conf$enddate)
    data_companies <- completePeriod2(companies, period, 
                    conf$str_startdate, conf$str_enddate)
}

# Fixed data
info_data = evol_info_data(sql_period, conf$startdate, conf$enddate)
latest_activity7 = last_activity(7)
latest_activity30 = last_activity(30)
latest_activity90 = last_activity(90)
latest_activity365 = last_activity(365)
info_data = merge(info_data, latest_activity7)
info_data = merge(info_data, latest_activity30)
info_data = merge(info_data, latest_activity90)
info_data = merge(info_data, latest_activity365)

if (conf$reports == 'companies') {
	info_data_companies = evol_info_data_companies (conf$startdate, conf$enddate)
	info_data = merge(info_data, info_data_companies, all = TRUE)
}

# Top committers
#top_committers_data <- list()
#top_committers_data[['committers.']]<-top_people(0, conf$startdate, conf$enddate, "committer")
#top_committers_data[['committers.last year']]<-top_people(365, conf$startdate, conf$enddate, "committer")
#top_committers_data[['committers.last month']]<-top_people(31, conf$startdate, conf$enddate, "committer")

# Top authors
#top_authors_data <- list()
#top_authors_data[['authors.']]<-top_people(0, conf$startdate, conf$enddate, "author")
#top_authors_data[['authors.last year']]<-top_people(365, conf$startdate, conf$enddate, "author")
#top_authors_data[['authors.last month']]<-top_people(31, conf$startdate, conf$enddate, "author")

#top_data <- c(top_committers_data, top_authors_data)
#createJSON (top_data, "data/json/scm-top.json")

# Top authors

top_authors_data <- top_authors(conf$startdate, conf$enddate)
#top_authors_data_2006 <- top_authors_year(2006)
#top_authors_data_2009 <- top_authors_year(2009)
#top_authors_data_2012 <- top_authors_year(2012)
top_authors_data <- list()
top_authors_data[['authors.']] <- top_authors_wo_affiliations(c("-Bot"), conf$startdate, conf$enddate)
createJSON (top_authors_data, "data/json/scm-top.json")

# Top files
top_files_modified_data = top_files_modified()

agg_data = merge(data_commits, data_committers, all = TRUE)
agg_data = merge(agg_data, data_authors, all = TRUE)
if (conf$reports == 'companies') 
	agg_data = merge(agg_data, data_companies, all = TRUE)
agg_data = merge(agg_data, data_files, all = TRUE)
agg_data = merge(agg_data, data_lines, all = TRUE)
agg_data = merge(agg_data, data_branches, all = TRUE)
agg_data = merge(agg_data, data_repositories, all = TRUE)
agg_data <- agg_data[order(agg_data$id), ]
agg_data[is.na(agg_data)] <- 0

# TODO: output dir read from params in command line
createJSON (agg_data, "data/json/scm-evolutionary.json")
createJSON (info_data, "data/json/scm-static.json")
#createJSON (top_committers_data, "data/json/scm-top.json")

people_list = people()
createJSON (people_list, "data/json/scm-people.json")

# TODO: Have a unique file, scm-top.json already exists, with all metrics
# createJSON (top_authors_data, "data/json/scm-top.json")
# createJSON (top_data, "data/json/scm-top.json")
#createJSON (top_authors_data_2006, "data/json/scm-top-authors_2006.json")
#createJSON (top_authors_data_2009, "data/json/scm-top-authors_2009.json")
#createJSON (top_authors_data_2012, "data/json/scm-top-authors_2012.json")

if (conf$reports == 'companies') {
	companies  <- companies_name(conf$startdate, conf$enddate)
    # companies  <- companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), conf$startdate, conf$enddate)
	companies <- companies$name
	createJSON(companies, "data/json/scm-companies.json")
	
	for (company in companies){
		company_name = paste(c("'", company, "'"), collapse='')
		company_aux = paste(c("", company, ""), collapse='')
		print (company_name)
		 
		commits <- company_commits(company_name, sql_res, conf$startdate, conf$enddate)        
        commits <- completePeriod2(commits, period, 
                        conf$str_startdate, conf$str_enddate)

        #Lines: two metrics. process each one isolate and merge
        lines <-company_lines(company_name, sql_res, conf$startdate, conf$enddate)
        lines<- completePeriodMulti(lines, c('added_lines','removed_lines'),period, 
                        conf$str_startdate, conf$str_enddate)
        
		files <- company_files(company_name, sql_res, conf$startdate, conf$enddate)
        files <- completePeriod2(files, period, 
                conf$str_startdate, conf$str_enddate)

		authors <- company_authors(company_name, sql_res, conf$startdate, conf$enddate)
        authors <- completePeriod2(authors, period, 
                conf$str_startdate, conf$str_enddate)

		committers <- company_committers(company_name, sql_res, conf$startdate, conf$enddate)
        committers <- completePeriod2(committers, period, 
                conf$str_startdate, conf$str_enddate, 'committers')
        		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)
		agg_data = merge(agg_data, committers, all = TRUE)
        agg_data <- agg_data[order(agg_data$id), ]
		
		createJSON(agg_data, paste(c("data/json/",company_aux,"-scm-evolutionary.json"), collapse=''))
				
		print ("static info")
		static_info <- evol_info_data_company(company_name, sql_period, conf$startdate, conf$enddate)
		createJSON(static_info, paste(c("data/json/",company_aux,"-scm-static.json"), collapse=''))
		
		print ("top authors")
		top_authors <- company_top_authors(company_name, conf$startdate, conf$enddate)
		createJSON(top_authors, paste(c("data/json/",company_aux,"-scm-top-authors.json"), collapse=''))
		top_authors_2006 <- company_top_authors_year(company_name, 2006) 
		createJSON(top_authors_2006, paste(c("data/json/",company_aux,"-scm-top-authors_2006.json"), collapse=''))
		top_authors_2009 <- company_top_authors_year(company_name, 2009)
		createJSON(top_authors_2009, paste(c("data/json/",company_aux,"-scm-top-authors_2009.json"), collapse=''))
		top_authors_2012 <- company_top_authors_year(company_name, 2012)
		createJSON(top_authors_2012, paste(c("data/json/",company_aux,"-scm-top-authors_2012.json"), collapse=''))	
	}
}

if (conf$reports == 'repositories') {
	repos  <- repos_name(conf$startdate, conf$enddate)
	repos <- repos$name
	createJSON(repos, "data/json/scm-repos.json")
	
	for (repo in repos) {
		repo_name = paste(c("'", repo, "'"), collapse='')
		repo_aux = paste(c("", repo, ""), collapse='')
		print (repo_name)
        
		commits <- repo_commits(repo_name, sql_res, conf$startdate, conf$enddate)
        commits <- completePeriod2(commits, period, 
                conf$str_startdate, conf$str_enddate)
        
		# print ("lines")
		# lines <- repo_lines(repo_name, period, conf$startdate, conf$enddate)
		lines <- ""

		files <- repo_files(repo_name, sql_res, conf$startdate, conf$enddate)
        files <- completePeriod2(files, period, 
                conf$str_startdate, conf$str_enddate)

		authors <- repo_authors(repo_name, sql_res, conf$startdate, conf$enddate)
        authors <- completePeriod2(authors, period, 
                conf$str_startdate, conf$str_enddate)

		committers <- repo_committers(repo_name, sql_res, conf$startdate, conf$enddate)
        committers <- completePeriod2(committers, period, 
                conf$str_startdate, conf$str_enddate)
		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)	
		agg_data = merge(agg_data, committers, all = TRUE)
        agg_data <- agg_data[order(agg_data$id), ]
		
		createJSON(agg_data, paste(c("data/json/",repo_aux,"-scm-evolutionary.json"), collapse=''))
		
		print ("static info")
		static_info <- evol_info_data_repo(repo_name, sql_period, conf$startdate, conf$enddate)
		createJSON(static_info, paste(c("data/json/",repo_aux,"-scm-static.json"), collapse=''))		
	}		
}

if (conf$reports == 'countries') {
	countries  <- scm_countries_names(conf$identities_db,conf$startdate, conf$enddate)
	countries <- countries$name
	createJSON(countries, "data/json/scm-countries.json")
	
	for (country in countries) {
        if (is.na(country)) next
        print (country)
        #data: two metrics. process each one isolate and merge
        data <- scm_countries_evol(conf$identities_db, country, sql_res, conf$startdate, conf$enddate)        
        data_commits <- data.frame(id=data$id,commits=data$commits)
        data_commits <- completePeriod2(data_commits, period, 
                conf$str_startdate, conf$str_enddate)
        data_authors <- data.frame(id=data$id,authors=data$authors)
        data_authors <- completePeriod2(data_authors, period, 
                conf$str_startdate, conf$str_enddate)
        data <- merge(data_commits,data_authors, all = TRUE)

        createJSON (data, paste("data/json/",country,"-scm-evolutionary.json",sep=''))
        
        # TODO: not using sql_period???
        data <- scm_countries_static(conf$identities_db, country, conf$startdate, conf$enddate)
        createJSON (data, paste("data/json/",country,"-scm-static.json",sep=''))        
    }
}

if (conf$reports == 'companies-countries'){
    companies  <- companies_name(conf$startdate, conf$enddate)
    companies <- companies$name
    for (company in companies){
        countries  <- scm_countries_names(conf$identities_db,conf$startdate, conf$enddate)
	countries <- countries$name
	for (country in countries) {
            company_name = paste(c("'", company, "'"), collapse='')
            company_aux = paste(c("", company, ""), collapse='')

            ###########
            if (is.na(country)) next
            print (paste(country, "<->", company))
            data <- scm_companies_countries_evol(conf$identities_db, company, country, sql_res, conf$startdate, conf$enddate)
            data <- completePeriod2(data, period, 
                                    conf$str_startdate, conf$str_enddate) 
            
            createJSON (data, paste("data/json/companycountry/",company,".",country,"-scm-evolutionary.json",sep=''))
            
            # TODO: not using sql_period???            
            data <- scm_countries_static(conf$identities_db, country, conf$startdate, conf$enddate)
            createJSON (data, paste("data/json/companycountry/",company,".",country,"-scm-static.json",sep=''))        

            #################
            
            
        }
    }
}

# Demographics

demos <- new ("Demographics","scm")
demos$age <- as.Date(conf$str_enddate) - as.Date(demos$firstdate)
demos$age[demos$age < 0 ] <- 0
aux <- data.frame(demos["id"], demos["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, "data/json/scm-demos-pyramid.json")

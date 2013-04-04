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

if (conf$granularity == 'months'){
   period = 'month'
   nperiod = 31
}
if (conf$granularity == 'weeks'){
   period='week'
   nperiod = 7
}

#Commits per month
data_commits <- evol_commits(nperiod, conf$startdate, conf$enddate)
data_commits = completeZeroPeriod(data_commits, conf$str_startdate, conf$str_enddate)
data_commits$week <- as.Date(conf$str_startdate) + data_commits$id * nperiod
data_commits$date  <- toTextDate(GetYear(data_commits$week), GetMonth(data_commits$week)+1)
data_commits <- data_commits[order(data_commits$id), ]
print(data_commits)

#Committers per month
data_committers = evol_committers(nperiod, conf$startdate, conf$enddate)
data_committers = completeZeroPeriod(data_committers, conf$str_startdate, conf$str_enddate)
data_committers$week <- as.Date(conf$str_startdate) + data_committers$id * nperiod
data_committers$date <- toTextDate(GetYear(data_committers$week), GetMonth(data_committers$week)+1)
data_committers <- data_committers[order(data_committers$id), ]
print(data_committers)

# Authors per month
data_authors = evol_authors(nperiod, conf$startdate, conf$enddate)
data_authors = completeZeroPeriod(data_authors, conf$str_startdate, conf$str_enddate)
data_authors$week <- as.Date(conf$str_startdate) + data_authors$id * nperiod
data_authors$date <- toTextDate(GetYear(data_authors$week), GetMonth(data_authors$week)+1)
data_authors <- data_authors[order(data_authors$id), ]
print (data_authors)

#Files per month
data_files = evol_files(nperiod, conf$startdate, conf$enddate)
data_files = completeZeroPeriod(data_files, conf$str_startdate, conf$str_enddate)
data_files$week <- as.Date(conf$str_startdate) + data_files$id * nperiod
data_files$date <- toTextDate(GetYear(data_files$week), GetMonth(data_files$week)+1)
data_files <- data_files[order(data_files$id), ]
print(data_files)

#Branches per month
data_branches = evol_branches(nperiod, conf$startdate, conf$enddate)
data_branches = completeZeroPeriod(data_branches, conf$str_startdate, conf$str_enddate)
data_branches$week <- as.Date(conf$str_startdate) + data_branches$id * nperiod
data_branches_date <- toTextDate(GetYear(data_branches$week), GetMonth(data_branches$week)+1)
data_branches <- data_branches[order(data_branches$id), ]
print(data_branches)

#Repositories per month
data_repositories = evol_repositories(nperiod, conf$startdate, conf$enddate)
data_repositories = completeZeroPeriod(data_repositories, conf$str_startdate, conf$str_enddate)
data_repositories$week <- as.Date(conf$str_startdate) + data_repositories$id * nperiod
data_repositories$date <- toTextDate(GetYear(data_repositories$week), GetMonth(data_repositories$week)+1)
data_repositories <- data_repositories[order(data_repositories$id), ]
print(data_repositories)

if (conf$reports == 'companies') { 
    data_companies = evol_companies(nperiod, conf$startdate, conf$enddate)
    data_companies = completeZeroPeriod(data_companies, conf$str_startdate, conf$str_enddate)
    data_companies$week <- as.Date(conf$str_startdate) + data_companies$id * nperiod
    print (data_companies)
    data_companies$date <- toTextDate(GetYear(data_companies$week), GetMonth(data_companies$week)+1)
    data_companies <- data_companies[order(data_companies$id), ]
}

# Fixed data
info_data = evol_info_data(period, conf$startdate, conf$enddate)

if (conf$reports == 'companies') {
	info_data_companies = evol_info_data_companies (conf$startdate, conf$enddate)
	info_data = merge(info_data, info_data_companies, all = TRUE)
}

# Top committers
top_committers_data <- list()
top_committers_data[['committers.']]<-top_committers(0, conf$startdate, conf$enddate)
top_committers_data[['committers.last year']]<-top_committers(365, conf$startdate, conf$enddate)
top_committers_data[['committers.last month']]<-top_committers(31, conf$startdate, conf$enddate)

# Top authors

#top_authors_data <- top_authors(conf$startdate, conf$enddate)
#top_authors_data_2006 <- top_authors_year(2006)
#top_authors_data_2009 <- top_authors_year(2009)
#top_authors_data_2012 <- top_authors_year(2012)
top_authors_data <- top_authors_wo_affiliations(c("-Bot"), conf$startdate, conf$enddate)

# Top files
top_files_modified_data = top_files_modified()

agg_data = merge(data_commits, data_committers, all = TRUE)
agg_data = merge(agg_data, data_authors, all = TRUE)
if (conf$reports == 'companies') 
	agg_data = merge(agg_data, data_companies, all = TRUE)
agg_data = merge(agg_data, data_files, all = TRUE)
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
createJSON (top_authors_data, "data/json/scm-top.json")
#createJSON (top_authors_data_2006, "data/json/scm-top-authors_2006.json")
#createJSON (top_authors_data_2009, "data/json/scm-top-authors_2009.json")
#createJSON (top_authors_data_2012, "data/json/scm-top-authors_2012.json")

if (conf$reports == 'companies') {
	companies  <- companies_name(conf$startdate, conf$enddate)
        companies  <- companies_name_wo_affs(c("-Bot", "-Individual", "-Unknown"), conf$startdate, conf$enddate)
	companies <- companies$name
	createJSON(companies, "data/json/scm-companies.json")
	
	for (company in companies){
		company_name = paste(c("'", company, "'"), collapse='')
		company_aux = paste(c("", company, ""), collapse='')
		print (company_name)
		 
		commits <- company_commits(company_name, nperiod, conf$startdate, conf$enddate)	
                if (length(commits) == 0) {
                    commits <- data.frame(id=numeric(0), commits=numeric(0))
                }
                commits = completeZeroPeriod(commits, conf$str_startdate, conf$str_enddate)
                commits$week <- as.Date(conf$str_startdate) + commits$id * nperiod
                commits$date <- toTextDate(GetYear(commits$week), GetMonth(commits$week)+1)
                commits <- commits[order(commits$id), ]
                print(commits)

		lines <-company_lines(company_name, nperiod, conf$startdate, conf$enddate)
                if (length(lines) == 0) {
                    lines <- data.frame(id=numeric(0), added_lines=numeric(0), removed_lines=numeric(0))
                }
                lines = completeZeroPeriod(lines, conf$str_startdate, conf$str_enddate)
                lines$week <- as.Date(conf$str_startdate) + lines$id * nperiod
                lines$date <- toTextDate(GetYear(lines$week), GetMonth(lines$week)+1)
                lines <- lines[order(lines$id), ]
                print(lines)

		files <- company_files(company_name, nperiod, conf$startdate, conf$enddate)
                if (length(files) == 0) {
                    lines <- data.frame(id=numeric(0), files=numeric(0))
                }
                files = completeZeroPeriod(files, conf$str_startdate, conf$str_enddate)
                files$week <- as.Date(conf$str_startdate) + files$id * nperiod
                files$date <- toTextDate(GetYear(files$week), GetMonth(files$week)+1)
                files <- files[order(files$id), ]
                print(files) 

		authors <- company_authors(company_name, nperiod, conf$startdate, conf$enddate)
                if (length(authors) == 0) {
                    lines <- data.frame(id=numeric(0), authors=numeric(0))
                }
                authors = completeZeroPeriod(authors, conf$str_startdate, conf$str_enddate)
                authors$week <- as.Date(conf$str_startdate) + authors$id * nperiod
                authors$date <- toTextDate(GetYear(authors$week), GetMonth(authors$week)+1)
                authors <- authors[order(authors$id), ]
                print(authors)

		committers <- company_committers(company_name, nperiod, conf$startdate, conf$enddate)
                if (length(committers) == 0) {
                    lines <- data.frame(id=numeric(0), committers=numeric(0))
                }
                committers = completeZeroPeriod(committers, conf$str_startdate, conf$str_enddate)
                committers$week <- as.Date(conf$str_startdate) + committers$id * nperiod
                committers$date <- toTextDate(GetYear(committers$week), GetMonth(committers$week)+1)
                committers <- committers[order(committers$id), ]
                print(committers)
		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)
		agg_data = merge(agg_data, committers, all = TRUE)
                agg_data <- agg_data[order(agg_data$id), ]
		
		createJSON(agg_data, paste(c("data/json/",company_aux,"-scm-evolutionary.json"), collapse=''))
		
		
		print ("static info")
		static_info <- evol_info_data_company(company_name, period, conf$startdate, conf$enddate)
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
		
		print ("commits") 
		commits <- repo_commits(repo_name, nperiod, conf$startdate, conf$enddate)
                if (length(commits) == 0) {
                    commits <- data.frame(id=numeric(0), commits=numeric(0))
                }
                commits = completeZeroPeriod(commits, conf$str_startdate, conf$str_enddate)
                commits$week <- as.Date(conf$str_startdate) + commits$id * nperiod
                commits$date <- toTextDate(GetYear(commits$week), GetMonth(commits$week)+1)
                commits <- commits[order(commits$id), ]
                
		# print ("lines")
		# lines <- repo_lines(repo_name, period, conf$startdate, conf$enddate)
		lines <- ""
		print ("files")
		files <- repo_files(repo_name, nperiod, conf$startdate, conf$enddate)
                if (length(files) == 0) {
                    lines <- data.frame(id=numeric(0), files=numeric(0))
                }
                files = completeZeroPeriod(files, conf$str_startdate, conf$str_enddate)
                files$week <- as.Date(conf$str_startdate) + files$id * nperiod
                files$date <- toTextDate(GetYear(files$week), GetMonth(files$week)+1)
                files <- files[order(files$id), ]        

		print ("people")
		authors <- repo_authors(repo_name, nperiod, conf$startdate, conf$enddate)
                if (length(authors) == 0) {
                    lines <- data.frame(id=numeric(0), authors=numeric(0))
                }
                authors = completeZeroPeriod(authors, conf$str_startdate, conf$str_enddate)
                authors$week <- as.Date(conf$str_startdate) + authors$id * nperiod
                authors$date <- toTextDate(GetYear(authors$week), GetMonth(authors$week)+1)
                authors <- authors[order(authors$id), ]

		committers <- repo_committers(repo_name, nperiod, conf$startdate, conf$enddate)
                if (length(committers) == 0) {
                    lines <- data.frame(id=numeric(0), committers=numeric(0))
                }
                committers = completeZeroPeriod(committers, conf$str_startdate, conf$str_enddate)
                committers$week <- as.Date(conf$str_startdate) + committers$id * nperiod
                committers$date <- toTextDate(GetYear(committers$week), GetMonth(committers$week)+1)
                committers <- committers[order(committers$id), ]
		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)	
		agg_data = merge(agg_data, committers, all = TRUE)
                agg_data <- agg_data[order(agg_data$id), ]
		
		createJSON(agg_data, paste(c("data/json/",repo_aux,"-scm-evolutionary.json"), collapse=''))
		
		print ("static info")
		static_info <- evol_info_data_repo(repo_name, period, conf$startdate, conf$enddate)
		createJSON(static_info, paste(c("data/json/",repo_aux,"-scm-static.json"), collapse=''))		
	}		
}

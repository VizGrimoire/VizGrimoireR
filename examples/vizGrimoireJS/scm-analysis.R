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
}
if (conf$granularity == 'weeks'){
   period='week'
}

#Commits per month
data_commits <- evol_commits(period, conf$startdate, conf$enddate)

#Committers per month
data_committers = evol_committers(period, conf$startdate, conf$enddate)

# Authors per month
data_authors = evol_authors(period, conf$startdate, conf$enddate)

#Files per month
data_files = evol_files(period, conf$startdate, conf$enddate)

#Branches per month
data_branches = evol_branches(period, conf$startdate, conf$enddate)

#Repositories per month
data_repositories = evol_repositories(period, conf$startdate, conf$enddate)

if (conf$reports == 'companies') data_companies = evol_companies(period, conf$startdate, conf$enddate)

# Fixed data
info_data = evol_info_data(period, conf$startdate, conf$enddate)

if (conf$reports == 'companies') {
	info_data_companies = evol_info_data_companies (conf$startdate, conf$enddate)
	info_data = merge(info_data, info_data_companies, all = TRUE)
}

# Top committers
top_committers_data <- list()
top_committers_data[['committers.']]<-top_committers(0, conf$startdate, conf$enddate)

# Top authors
top_authors_data <- top_authors_wo_affiliations(c("-Bot"), conf$startdate, conf$enddate)
#top_authors_data <- top_authors(conf$startdate, conf$enddate)

# Top files
top_files_modified_data = top_files_modified()

agg_data = merge(data_commits, data_committers, all = TRUE)
agg_data = merge(agg_data, data_authors, all = TRUE)
if (conf$reports == 'companies') 
	agg_data = merge(agg_data, data_companies, all = TRUE)
agg_data = merge(agg_data, data_files, all = TRUE)
agg_data = merge(agg_data, data_branches, all = TRUE)
agg_data = merge(agg_data, data_repositories, all = TRUE)
agg_data[is.na(agg_data)] <- 0

# TODO: output dir read from params in command line
createJSON (agg_data, "data/json/scm-evolutionary.json")
createJSON (info_data, "data/json/scm-static.json")
#createJSON (top_committers_data, "data/json/scm-top.json")

people_list = people()
createJSON (people_list, "data/json/scm-people.json")

# TODO: Have a unique file, scm-top.json already exists, with all metrics
createJSON (top_authors_data, "data/json/scm-top-authors.json")
#createJSON (top_authors_data_2006, "data/json/scm-top-authors_2006.json")
#createJSON (top_authors_data_2009, "data/json/scm-top-authors_2009.json")
#createJSON (top_authors_data_2012, "data/json/scm-top-authors_2012.json")

if (conf$reports == 'companies') {
	companies  <- companies_name(conf$startdate, conf$enddate)
	companies <- companies$name
	createJSON(companies, "data/json/scm-companies.json")
	
	for (company in companies){
		company_name = paste(c("'", company, "'"), collapse='')
		company_aux = paste(c("", company, ""), collapse='')
		print (company_name)
		 
		commits <- company_commits(company_name, period, conf$startdate, conf$enddate)	
		lines <-company_lines(company_name, period, conf$startdate, conf$enddate)
		files <- company_files(company_name, period, conf$startdate, conf$enddate)
		authors <- company_authors(company_name, period, conf$startdate, conf$enddate)
		committers <- company_committers(company_name, period, conf$startdate, conf$enddate)
		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)
		agg_data = merge(agg_data, committers, all = TRUE)
		
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
		commits <- repo_commits(repo_name, period, conf$startdate, conf$enddate)	
		# print ("lines")
		# lines <- repo_lines(repo_name, period, conf$startdate, conf$enddate)
		lines <- ""
		print ("files")
		files <- repo_files(repo_name, period, conf$startdate, conf$enddate)
		print ("people")
		authors <- repo_authors(repo_name, period, conf$startdate, conf$enddate)
		committers <- repo_committers(repo_name, period, conf$startdate, conf$enddate)
		
		agg_data = merge(commits, lines, all = TRUE)
		agg_data = merge(agg_data, files, all = TRUE)
		agg_data = merge(agg_data, authors, all = TRUE)	
		agg_data = merge(agg_data, committers, all = TRUE)
		
		createJSON(agg_data, paste(c("data/json/",repo_aux,"-scm-evolutionary.json"), collapse=''))
		
		print ("static info")
		static_info <- evol_info_data_repo(repo_name, period, conf$startdate, conf$enddate)
		createJSON(static_info, paste(c("data/json/",repo_aux,"-scm-static.json"), collapse=''))		
	}		
}

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

if (conf$backend == 'allura') closed_condition <- "new_value='CLOSED'"
if (conf$backend == 'bugzilla') 
	closed_condition <- "new_value='RESOLVED' OR new_value='CLOSED'"
if (conf$backend == 'github') closed_condition <- "field='closed'"
if (conf$backend == 'jira') 
	closed_condition <- "new_value='RESOLVED' OR new_value='CLOSED'"

closed_monthly <- evol_closed(closed_condition)
changed_monthly <- evol_changed()
open_monthly <- evol_opened()
repos_monthly <- its_evol_repositories();

issues_monthly <- merge (open_monthly, closed_monthly, all = TRUE)
issues_monthly <- merge (issues_monthly, changed_monthly, all = TRUE)
issues_monthly <- merge (issues_monthly, repos_monthly, all = TRUE)
issues_monthly[is.na(issues_monthly)] <- 0

issues_monthly <- completeZeroMonthly(issues_monthly)

createJSON (issues_monthly, "data/json/its-evolutionary.json")

all_static_info <- its_static_info()
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
		closed <- repo_evol_closed(repo_name, closed_condition)
		changed <- repo_evol_changed(repo_name)
		opened <- repo_evol_opened(repo_name)		
		agg_data = merge(closed, changed, all = TRUE)
		agg_data = merge(agg_data, opened, all = TRUE)	
		agg_data[is.na(agg_data)] <- 0				
		createJSON(agg_data, paste(c("data/json/",repo_file,"-its-evolutionary.json"), collapse=''))
		
		# STATIC INFO
		static_info <- its_static_info_repo(repo_name)
		createJSON(static_info, paste(c("data/json/",repo_file,"-its-static.json"), collapse=''))		
	}
}

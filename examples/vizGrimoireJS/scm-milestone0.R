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
##
##
## Usage:
##  R --no-restore --no-save < scm-milestone0.R
## or
##  R CMD BATCH scm-milestone0.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
## conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
##                            user = "root", password = NULL,
##                            host = "127.0.0.1", port = 3308)
## SetDBChannel (database = conf$database,
##               user = conf$user, password = conf$password,
##               host = conf$host, port = conf$port)
conf <- ConfFromParameters(dbschema = "kdevelop", user = "jgb", password = "XXX")
SetDBChannel (database = conf$database, user = conf$user, password = conf$password)

#Commits per month
data_commits <- evol_commits()

#Committers per month
data_committers = evol_committers()

# Authors per month
data_authors = evol_authors()


#Files per month
data_files = evol_files()

#Branches per month
data_branches = evol_branches()

#Repositories per month
data_repositories = evol_repositories()

# Fixed data
info_data = evol_info_data()

# Top committers
top_committers_data <- list()
top_committers_data[['committers.']]<-top_committers()
top_committers_data[['committers.last year']]<-top_committers(365)
top_committers_data[['committers.last month']]<-top_committers(31)

# Top files
top_files_modified_data = top_files_modified()

agg_data = merge(data_commits, data_committers, all = TRUE)
agg_data = merge(agg_data, data_authors, all = TRUE)
agg_data = merge(agg_data, data_files, all = TRUE)
agg_data = merge(agg_data, data_branches, all = TRUE)
agg_data = merge(agg_data, data_repositories, all = TRUE)
agg_data[is.na(agg_data)] <- 0

createJSON (agg_data, "scm-milestone0.json")
createJSON (info_data, "scm-info-milestone0.json")
createJSON (top_committers_data, "scm-top-milestone0.json")

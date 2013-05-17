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

# period of time
if (conf$granularity == 'months'){
   period = 'month'
   nperiod = 31
}
if (conf$granularity == 'weeks'){
   period = 'week'
   nperiod = 7
}

# dates
startdate <- conf$startdate
enddate <- conf$enddate

# database with unique identities
identities_db <- conf$identities_db

print(startdate)

closed <- evol_closed_gerrit(nperiod, startdate, enddate)
if (length(closed) == 0) {
    closed <- data.frame(id=numeric(0), closers=numeric(0),closed=numeric(0))
} 
closed$week <- as.Date(conf$str_startdate) + closed$id * nperiod
closed$date <- toTextDate(GetYear(closed$week), GetMonth(closed$week)+1)

open <- evol_opened_gerrit(nperiod, startdate, enddate)
if (length(open) == 0) {
    open <- data.frame(id=numeric(0), opened=numeric(0), openers=numeric(0))
} 
open$week <- as.Date(conf$str_startdate) + open$id * nperiod
open$date <- toTextDate(GetYear(open$week), GetMonth(open$week)+1)

issues <- merge (open, closed, all = TRUE)

issues[is.na(issues)] <- 0
issues <- issues[order(issues$id),]
createJSON (issues, "data/json/its-evolutionary.json")

# all_static_info <- its_static_info_gerrit(startdate, enddate)
# createJSON (all_static_info, "data/json/its-static.json")

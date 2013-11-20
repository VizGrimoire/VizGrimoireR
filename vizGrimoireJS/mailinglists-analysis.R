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
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Example of usage:
## R --vanilla --args -d database -u root  < mailinglists-analysis.R

library("vizgrimoire")
library("ISOweek")

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)
destdir <- conf$destination

# period of time
if (conf$granularity == 'years') { period = 'year'
} else if (conf$granularity == 'months') { period = 'month'
} else if (conf$granularity == 'weeks') { period = 'week'
} else if (conf$granularity == 'days'){ period = 'day'
} else {stop(paste("Incorrect period:",conf$granularity))}

identities_db = conf$identities_db

# multireport
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]

# dates
startdate <- conf$startdate
enddate <- conf$enddate

rfield = reposField()


data <- EvolEmailsSent(period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggEmailsSent(period, startdate, enddate, identities_db, list(NA, NA))
print(data)

data <- EvolThreads(period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggThreads(period, startdate, enddate, identities_db, list(NA, NA))
print(data)

data <- EvolMLSRepositories(rfield, period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggMLSRepositories(rfield, period, startdate, enddate, identities_db, list(NA, NA))
print(data)

data <- EvolMLSResponses(period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggMLSResponses(period, startdate, enddate, identities_db, list(NA, NA))
print(data)

data <- EvolMLSInit(period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggMLSInit(period, startdate, enddate, identities_db, list(NA, NA))
print(data)

data <- EvolMLSSenders(period, startdate, enddate, identities_db, list(NA, NA))
print(data)
data <- AggMLSSenders(period, startdate, enddate, identities_db, list(NA, NA))
print(data)


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
##   Alvaro del Castillo <acs@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -d dbname < irc-analysis.R

library("vizgrimoire")
library("ISOweek")
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 


conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)

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

#############
# STATIC DATA
#############

static_data = GetIRCStaticData(period, conf$startdate, conf$enddate, conf$identities_db)
createJSON (static_data, paste(destdir,"/irc-static.json", sep=''))

###################
# EVOLUTIONARY DATA
###################

evol_data = GetIRCEvolutionaryData(period, conf$startdate, conf$enddate, conf$identities_db)
evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
createJSON (evol_data, paste(destdir,"/irc-evolutionary.json", sep=''))


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

# BOTS filtered
bots = c('wikibugs','gerrit-wm','wikibugs_','wm-bot','')

#############
# STATIC DATA
#############

# Tendencies
diffsent.365 = GetIRCDiffSentDays(period, conf$enddate, 365)
diffsenders.365 = GetIRCDiffSendersDays(period, conf$enddate, conf$identities_db, 365)
diffsent.30 = GetIRCDiffSentDays(period, conf$enddate, 30)
diffsenders.30 = GetIRCDiffSendersDays(period, conf$enddate, conf$identities_db, 30)
diffsent.7 = GetIRCDiffSentDays(period, conf$enddate, 7)
diffsenders.7 = GetIRCDiffSendersDays(period, conf$enddate, conf$identities_db, 7)

static.data = GetStaticDataIRC(period, conf$startdate, conf$enddate, conf$identities_db)
static.data = merge(static.data, diffsent.365)
static.data = merge(static.data, diffsent.30)
static.data = merge(static.data, diffsent.7)
static.data = merge(static.data, diffsenders.365)
static.data = merge(static.data, diffsenders.30)
static.data = merge(static.data, diffsenders.7)

createJSON (static.data, paste(destdir,"/irc-static.json", sep=''))

###################
# EVOLUTIONARY DATA
###################

evol_data = GetEvolDataIRC(period, conf$startdate, conf$enddate, conf$identities_db)
evol_data <- completePeriodIds(evol_data, conf$granularity, conf)
createJSON (evol_data, paste(destdir,"/irc-evolutionary.json", sep=''))

###################
# PEOPLE
###################
if ('people' %in% reports){
    people = GetListPeopleIRC(conf$startdate, conf$enddate)
    people = people$id
    limit = 30
    if (length(people)<limit) limit = length(people);
    people = people[1:limit]
    createJSON(people, paste(destdir,"/irc-people.json",sep=''))

    for (upeople_id in people){
        evol = GetEvolPeopleIRC(upeople_id, period, conf$startdate, conf$enddate)
        evol <- completePeriodIds(evol, conf$granularity, conf)
        evol[is.na(evol)] <- 0
        createJSON(evol, paste(destdir,"/people-",upeople_id,"-irc-evolutionary.json", sep=''))

        static <- GetStaticPeopleIRC(upeople_id, conf$startdate, conf$enddate)
        createJSON(static, paste(destdir,"/people-",upeople_id,"-irc-static.json", sep=''))
    }
}

###################
# MULTI REPOSITORY
###################
if ('repositories' %in% reports) {
    repos <- GetReposNameIRC()
    createJSON (repos, paste(destdir,"/irc-repos.json", sep=''))
    print (repos)

    for (repo in repos) {
        # Static data
        data<-GetRepoStaticSentSendersIRC(repo, conf$startdate, conf$enddate)
        createJSON (data, paste(destdir, "/",repo,"-irc-static.json",sep=''))                
        # Evol data
        data<-GetRepoEvolSentSendersIRC(repo, period, conf$startdate, conf$enddate)
        data <-completePeriodIds(data, conf$granularity, conf)                
        createJSON (data, paste(destdir,"/",repo,"-irc-evolutionary.json",sep=''))        
    }
}

#######
# TOPS
#######

top_senders <- list()
top_senders[['senders.']] <- GetTopSendersIRC(0, conf$startdate, conf$enddate, conf$identities_db, bots)
top_senders[['senders.last year']]<- GetTopSendersIRC(365, conf$startdate, conf$enddate, conf$identities_db, bots)
top_senders[['senders.last month']]<- GetTopSendersIRC(31, conf$startdate, conf$enddate, conf$identities_db, bots)
createJSON (top_senders, paste(destdir,"/irc-top.json", sep=''))


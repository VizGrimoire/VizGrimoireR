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
##   Alvaro del Castillo San Felix <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --no-restore --no-save < mls-milestone0.R
## or
##  R CMD BATCH mls-milestone0.R
##

library("vizgrimoire")

conf <- ConfFromOptParse()
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

identities_db = conf$identities_db

# dates
startdate <- conf$startdate
enddate <- conf$enddate

# destination directory
destdir <- conf$destination

# Aggregated data
if (conf$reports == 'countries'){
    static_data <- mls_static_info(startdate, enddate, conf$reports)
} else{
    static_data <- mls_static_info(startdate, enddate)
}
latest_activity7 <- last_activity_mls(7)
latest_activity30 <- last_activity_mls(30)
latest_activity90 <- last_activity_mls(90)
latest_activity365 <- last_activity_mls(365)
static_data = merge(static_data, latest_activity7)
static_data = merge(static_data, latest_activity30)
static_data = merge(static_data, latest_activity90)
static_data = merge(static_data, latest_activity365)
createJSON (static_data, paste(c(destdir,"/mls-static.json"), collapse=''))

# Mailing lists
query <- new ("Query", sql = "select distinct(mailing_list) from messages")
mailing_lists <- run(query)

if (is.na(mailing_lists$mailing_list)) {
    print ("URL Mailing List")
    query <- new ("Query",
                  sql = "select distinct(mailing_list_url) from messages")
    mailing_lists <- run(query)
    mailing_lists_files <- run(query)
    mailing_lists_files$mailing_list = gsub("/","_",mailing_lists$mailing_list)
    # print (mailing_lists)
    createJSON (mailing_lists_files, paste(c(destdir, "/mls-lists.json"), collapse=''))
    repos <- mailing_lists_files$mailing_list
    createJSON(repos, paste(c(destdir, "/mls-repos.json"), collapse=''))
} else {
    print (mailing_lists)
    createJSON (mailing_lists, paste(c(destdir, "/mls-lists.json"), collapse=''))
	repos <- mailing_lists$mailing_list;
	createJSON(repos, paste(c(destdir, "/mls-repos.json"), collapse=''))
}

if (conf$reports == 'countries') {
    countries <- countries_names(identities_db, startdate, enddate) 
    createJSON (countries, paste(c(destdir, "/mls-countries.json"), collapse=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        data <- analyze.monthly.mls.countries.evol(identities_db, country, nperiod, startdate, enddate)
        data <- completePeriod(data, nperiod, conf)        
        createJSON (data, paste(c(destdir, "/",country,"-mls-evolutionary.json"), collapse=''))
        
        data <- analyze.monthly.mls.countries.static(identities_db, country, startdate, enddate)
        createJSON (data, paste(c(destdir, "/",country,"-mls-static.json"), collapse=''))
    }
}

for (mlist in mailing_lists$mailing_list) {
    
    # Evol data
    data<-analyze.monthly.list.evol(mlist, nperiod, startdate, enddate)
    data <- completePeriod(data, nperiod, conf)
    data[is.na(data)] <- 0
    data <- data[order(data$id),]
    
    listname_file = gsub("/","_",mlist)
    
    # TODO: Multilist approach. We will obsolete it in future
    createJSON (data, paste(c(destdir, "/mls-",listname_file,"-evolutionary.json"), collapse=''))
    # Multirepos filename
    createJSON (data, paste(c(destdir, "/",listname_file,"-mls-evolutionary.json"), collapse=''))
        
    # Static data
    data<-analyze.monthly.list.static(mlist, nperiod, startdate, enddate)
    # TODO: Multilist approach. We will obsolete it in future
	createJSON (data, paste(c(destdir, "/mls-",listname_file,"-static.json"), collapse=''))
	# Multirepos filename
	createJSON (data, paste(c(destdir, "/",listname_file,"-mls-static.json"), collapse=''))   
}

if (conf$reports == 'countries'){
    data.monthly <- get.monthly(nperiod, startdate, enddate, conf$reports)
} else{
    data.monthly <- get.monthly(nperiod, startdate, enddate)
}
data.monthly <- completePeriod(data.monthly, nperiod, conf)
createJSON (data.monthly, paste(c(destdir, "/mls-evolutionary.json"), collapse=''))

# Top senders
# top_senders_data <- top_senders_wo_affs(c("-Bot"), identities_db, startdate, enddate)
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders(0, conf$startdate, conf$enddate,identites_db)
top_senders_data[['senders.last year']]<-top_senders(365, conf$startdate, conf$enddate,identites_db)
top_senders_data[['senders.last month']]<-top_senders(31, conf$startdate, conf$enddate,identites_db)

createJSON (top_senders_data, paste(c(destdir, "/mls-top.json"), collapse=''))

# People list
# query <- new ("Query", 
# 		sql = "select email_address as id, email_address, name, username from people")
# people <- run(query)
# createJSON (people, "data/json/mls-people.json")


# Companies information
if (conf$reports == 'companies'){
    
    company_names = companies_names(identities_db, startdate, enddate)
    # company_names = companies_names_wo_affs(c("-Bot", "-Individual", "-Unknown"), identities_db, startdate, enddate)

    createJSON(company_names$name, paste(c(destdir, "/mls-companies.json"), collapse=''))
   
    for (company in company_names$name){       
        print (company)
        company_name = paste("'",company,"'",sep="")
        post_posters = company_posts_posters (company_name, identities_db, nperiod, startdate, enddate)
        post_posters <- completePeriod(post_posters, nperiod, conf)        
        createJSON(post_posters, paste(c(destdir, "/",company,"-mls-evolutionary.json"), collapse=''))
        
        top_senders = company_top_senders (company_name, identities_db, period, startdate, enddate)
        createJSON(top_senders, paste(c(destdir, "/",company,"-mls-top-senders.json"), collapse=''))

        static_info = company_static_info(company_name, identities_db, startdate, enddate)
        createJSON(static_info, paste(c(destdir, "/",company,"-mls-static.json"), collapse=''))
    }
}

# Demographics

demos <- new ("Demographics","mls",6)
demos$age <- as.Date(conf$str_enddate) - as.Date(demos$firstdate)
demos$age[demos$age < 0 ] <- 0
aux <- data.frame(demos["id"], demos["age"])
new <- list()
new[['date']] <- conf$str_enddate
new[['persons']] <- aux
createJSON (new, paste(c(destdir, "/mls-demographics-aging.json"), collapse=''))

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

# Aggregated data
static_data <- mls_static_info(startdate, enddate)
createJSON (static_data, paste("data/json/mls-static.json",sep=''))

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
    createJSON (mailing_lists_files, "data/json/mls-lists.json")
    repos <- mailing_lists_files$mailing_list
    createJSON(repos, "data/json/mls-repos.json")	
} else {
    print (mailing_lists)
    createJSON (mailing_lists, "data/json/mls-lists.json")
	repos <- mailing_lists$mailing_list;
	createJSON(repos, "data/json/mls-repos.json")	
}

if (conf$reports == 'countries') {    
    # Countries
    country_limit = 30
    q <- paste("SELECT count(m.message_id) as total, country 
                FROM messages m  
                JOIN messages_people mp ON mp.message_ID=m.message_id  
                JOIN people p ON mp.email_address = p.email_address 
                GROUP BY country 
                ORDER BY total desc LIMIT ", country_limit)
    query <- new ("Query", sql = q)
    data <- run(query)
    countries<-data$country
    createJSON (countries, paste("data/json/mls-countries.json",sep=''))
    
    for (country in countries) {
        if (is.na(country)) next
        print (country)
        analyze.monthly.mls.countries(country, period, startdate, enddate)
    }
}

for (mlist in mailing_lists$mailing_list) {
    analyze.monthly.list(mlist, nperiod, startdate, enddate)
}

data.monthly <- get.monthly(nperiod, startdate, enddate)
data.monthly = completeZeroPeriod(data.monthly, conf$str_startdate, conf$str_enddate)
data.monthly$week <- as.Date(conf$str_startdate) + data.monthly$id * nperiod
data.monthly$date  <- toTextDate(GetYear(data.monthly$week), GetMonth(data.monthly$week)+1)
data.monthly <- data.monthly[order(data.monthly$id), ]
createJSON (data.monthly, paste("data/json/mls-evolutionary.json"))

# Top senders
top_senders_data <- top_senders_wo_affs(c("-Bot"), identities_db, startdate, enddate)
#top_senders_data <- list()
#top_senders_data[['senders.']]<-top_senders()
#top_senders_data[['senders.last year']]<-top_senders(365)
#top_senders_data[['senders.last month']]<-top_senders(31)

createJSON (top_senders_data, "data/json/mls-top.json")

# People list
query <- new ("Query", 
		sql = "select email_address as id, email_address, name, username from people")
people <- run(query)
createJSON (people, "data/json/mls-people.json")


# Companies information
if (conf$reports == 'companies'){
    
    #company_names = companies_names(identities_db, startdate, enddate)
    company_names = companies_names_wo_affs(c("-Bot", "-Individual", "-Unknown"), identities_db, startdate, enddate)

    createJSON(company_names$name, "data/json/mls-companies.json")
   
    for (company in company_names$name){       
        print (company)
        company_name = paste("'",company,"'",sep="")
        post_posters = company_posts_posters (company_name, identities_db, nperiod, startdate, enddate)
        if (length(post_posters) == 0) {
            post_posters <- data.frame(id=numeric(0), sent=numeric(0), senders=numeric(0))
        }
        post_posters = completeZeroPeriod(post_posters, conf$str_startdate, conf$str_enddate)
        post_posters$week <- as.Date(conf$str_startdate) + post_posters$id * nperiod
        post_posters$date  <- toTextDate(GetYear(post_posters$week), GetMonth(post_posters$week)+1)
        print(post_posters)
        post_posters <- post_posters[order(post_posters$id), ]

        createJSON(post_posters, paste("data/json/",company,"-mls-evolutionary.json", sep=""))

        top_senders = company_top_senders (company_name, identities_db, period, startdate, enddate)
        createJSON(top_senders, paste("data/json/",company,"-mls-top-senders.json", sep=""))

        static_info = company_static_info(company_name, identities_db, startdate, enddate)
        createJSON(static_info, paste("data/json/",company,"-mls-static.json", sep=""))
    }
}

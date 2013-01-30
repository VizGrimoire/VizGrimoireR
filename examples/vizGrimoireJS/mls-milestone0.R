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
##
##
## Usage:
##  R --no-restore --no-save < mls-milestone0.R
## or
##  R CMD BATCH mls-milestone0.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
## conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
##                            user = "root", password = NULL,
##                            host = "127.0.0.1", port = 3308)
## SetDBChannel (database = conf$database,
##               user = conf$user, password = conf$password,
##               host = conf$host, port = conf$port)
conf <- ConfFromParameters(dbschema = "acs_mlstats_allura_all", group = "fuego")
SetDBChannel (database = conf$database, group = conf$group)


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
    createJSON (mailing_lists_files, "mls-lists-milestone0.json")
} else {
    print (mailing_lists)
    createJSON (mailing_lists, "mls-lists-milestone0.json")
}

# Aggregated data
q <- "SELECT count(*) as sent,
        DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
        DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date
        FROM messages"
query <- new ("Query", sql = q)
num_msg <- run(query)
query <- new ("Query", sql = "SELECT count(*) as senders from people")
num_ppl <- run(query)

agg_data = merge(num_msg,num_ppl)

createJSON (agg_data, paste("mls-info-milestone0.json",sep=''))

for (mlist in mailing_lists$mailing_list) {
    analyze.monthly.list(mlist, "mls-")
}
data.monthly <- get.monthly()
createJSON (agg_data, "mls-milestone0.json")

# Top senders
top_senders_data <- list()
top_senders_data[['senders.']]<-top_senders()
top_senders_data[['senders.last year']]<-top_senders(365)
top_senders_data[['senders.last month']]<-top_senders(31)

createJSON (top_senders_data, "mls-top-milestone0.json")

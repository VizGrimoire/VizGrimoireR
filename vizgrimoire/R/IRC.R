## Copyright (C) 2013 Bitergia
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
## This file is a part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## IRC.R
##
## Queries for source code review data analysis
##
## Authors:
##   Alvaro del Castillo <acs@bitergia.com>


GetStaticDataIRC <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){
    
    # 1- Retrieving information
    sent <- StaticNumSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders <- StaticNumSendersIRC(period, startdate, enddate, i_db, type_analysis)
    
    # 2- Merging information
    static_data = merge(sent, senders)
    
    return (static_data)    
}

GetEvolutionaryDataIRC <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){
    
    # 1- Retrieving information
    sent <- EvolSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders <- EvolSendersIRC(period, startdate, enddate, i_db, type_analysis)
    
    # 2- Merging information
    evol_data = merge(sent, senders, all = TRUE)
    
    return (evol_data)
}

StaticNumSentIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(message) as sent,
            DATE_FORMAT (min(date), '%Y-%m-%d') as first_date, 
            DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    from <- " FROM irclog "
    where <- paste(" where date >=", startdate, " and
                     date < ", enddate, sep="")
    q <- paste(select, from, where)    
    return(ExecuteQuery(q))
}

StaticNumSendersIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(distinct(nick)) as senders"
    from <- " FROM irclog "
    where <- paste(" where date >=", startdate, " and
                    date < ", enddate, sep="")
    q <- paste(select, from, where)    
    return(ExecuteQuery(q))
}

GetSentIRC <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){    
    fields = " count(distinct(message)) as sent "
    tables = paste(" irclog ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")    
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))
}

EvolSentIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetSentIRC(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetSendersIRC <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){    
    fields = " count(distinct(nick)) as senders "
    tables = paste(" irclog ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")    
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))
}

EvolSendersIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetSendersIRC(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetTopSendersIRC <- function(days = 0, startdate, enddate, bots) {
    date_limit = ""
    filter_bots = ''
    for (bot in bots){
        filter_bots <- paste(filter_bots, " nick<>'",bot,"' and ",sep="")
    }
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(date) from irclog limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, date)<",days)
    }
    q <- paste("SELECT nick as senders,
                    count(id) as sent
              	FROM irclog
                WHERE ", filter_bots, "
                    date >= ", startdate, " and
                    date  < ", enddate, " ", date_limit, "
                    GROUP BY senders
                    ORDER BY sent desc
                    LIMIT 10;", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}
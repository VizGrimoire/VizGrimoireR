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

# SQL Metaqueries

GetIRCSQLRepositoriesFrom <- function(){
    # tables necessary for repositories
    return (", channels c")    
}

GetIRCSQLRepositoriesWhere <- function(repository){
    # filters necessaries for repositories
    return (paste(" i.channel_id = c.id and c.name=", repository, " ", sep=""))
}

GetIRCSQLCompaniesFrom <- function(i_db){
    # tables necessary to companies analysis
    return(paste(" , people_upeople pup,
                   ",i_db,".companies c,
                   ",i_db,".upeople_companies upc", sep=""))
}

GetIRCSQLCompaniesWhere <- function(name){
    # filters necessary to companies analysis
    return(paste(" i.nick = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.company_id = c.id and
                   i.submitted_on >= upc.init and
                   i.submitted_on < upc.end and
                   c.name = ",name, sep=""))
}

GetIRCSQLCountriesFrom <- function(i_db){
    # tables necessary to countries analysis
    return(paste(" , people_upeople pup,
                   ",i_db,".countries c,
                   ",i_db,".upeople_countries upc", sep=""))
}

GetIRCSQLCcountriesWhere <- function(name){
    # filters necessary to countries analysis
    return(paste(" i.nick = pup.people_id and
                   pup.upeople_id = upc.upeople_id and
                   upc.country_id = c.id and
                   c.name = ",name, sep=""))
}

GetIRCSQLDomainsFrom <- function(i_db){
    # tables necessary to domains analysis
    return(paste(" , people_upeople pup,
                   ",i_db,".domains d,
                   ",i_db,".upeople_domains upd", sep=""))

}

GetIRCSQLDomainsWhere <- function(){
    # filters necessary to domains analysis
    return(paste(" i.nick = pup.people_id and
                   pup.upeople_id = upd.upeople_id and
                   upd.domain_id = d.id and
                   d.name = ",name, sep=""))
}


GetTablesOwnUniqueIdsIRC <- function() {
    tables = 'irclog, people_upeople pup'
    return (tables)
}

GetFiltersOwnUniqueIdsIRC <- function () {
    filters = 'pup.people_id = irclog.nick'
    return (filters) 
}


##############
# Generic functions to check evolutionary or aggregated info
# and for the execution of the final query
##############

BuildQuery <- function(period, startdate, enddate, date_field, fields, tables, filters, evolutionary){
    # Select the way to evolutionary or aggregated dataset

    q = ""

    if (evolutionary) {
         q <- GetSQLPeriod(period, date_field, fields, tables, filters,
            startdate, enddate)
    } else {
         q <- GetSQLGlobal(date_field, fields, tables, filters,
                           startdate, enddate)
    }

    return(q)
}


ExecuteQuery <- function(q){
    # This function creates a new object Query and
    # returns the result
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

GetIRCSQLReportFrom <- function(identities_db, type_analysis){
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    analysis = type_analysis[1]
    value = type_analysis[2]

    from = ""

    if (! is.na(analysis)){
        from <- ifelse (analysis == 'repository', paste(from, GetIRCSQLRepositoriesFrom()),
                ifelse (analysis == 'company', paste(from, GetIRCSQLCompaniesFrom(identities_db)),
                ifelse (analysis == 'country', paste(from, GetIRCSQLCountriesFrom(identities_db)),
                ifelse (analysis == 'domain', paste(from, GetIRCSQLDomainsFrom(identities_db)),
                NA))))
    }
    return (from)
}

GetIRCSQLReportWhere <- function(type_analysis){
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis
    analysis = type_analysis[1]
    value = type_analysis[2]
    where = ""

    if (! is.na(analysis)){
        where <- ifelse (analysis == 'repository', paste(where, GetIRCSQLRepositoriesWhere(value)),
                ifelse (analysis == 'company', paste(where, GetIRCSQLCompaniesWhere(value)),
                ifelse (analysis == 'country', paste(where, GetIRCSQLCountriesWhere(value)),
                ifelse (analysis == 'domain', paste(where, GetIRCSQLDomainsWhere(value)),
                NA))))
    }
    return (where)
}




# GLOBAL

GetStaticDataIRC <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){

    # 1- Retrieving information
    sent <- StaticNumSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders <- StaticNumSendersIRC(period, startdate, enddate, i_db, type_analysis)
    repositories <- StaticNumRepositoriesIRC(period, startdate	, enddate, i_db, type_analysis)

    # 2- Merging information
    static_data = merge(sent, senders)
    static_data = merge(static_data, repositories)

    return (static_data)
}

GetEvolDataIRC <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){

    # 1- Retrieving information
    sent <- EvolSentIRC(period, startdate, enddate, i_db, type_analysis)
    senders <- EvolSendersIRC(period, startdate, enddate, i_db, type_analysis)
    repositories <- EvolRepositoriesIRC(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    evol_data = merge(sent, senders, all=TRUE)
    evol_data = merge(evol_data, repositories, all=TRUE)

    return (evol_data)
}

StaticNumSentIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(message) as sent,
            DATE_FORMAT (min(date), '%Y-%m-%d') as first_date, 
            DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    from <- " FROM irclog "
    where <- paste(" where date >=", startdate, " and
                     date < ", enddate, " and
                     type='COMMENT' ", sep="")
    q <- paste(select, from, where)
    return(ExecuteQuery(q))
}

StaticNumSendersIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(distinct(nick)) as senders"
    from <- " FROM irclog "
    where <- paste(" where date >=", startdate, " and
                    date < ", enddate, " and
                    type='COMMENT' ",sep="")
    q <- paste(select, from, where)
    return(ExecuteQuery(q))
}

StaticNumRepositoriesIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    select <- "SELECT COUNT(DISTINCT(channel_id)) AS repositories "
    from <- "FROM irclog "
    where <- paste("WHERE date >=", startdate, " AND
                    date < ", enddate, " and
                    type='COMMENT' ", sep="")
    q <- paste(select, from, where)
    return(ExecuteQuery(q))
}

GetSentIRC <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){    
    fields = " count(distinct(message)) as sent "
    tables = paste(" irclog ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")
    filters <- paste(filters, "and type='COMMENT' ", sep="")
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
    filters <- paste(filters, "and type='COMMENT' ", sep="")
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))
}

EvolSendersIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetSendersIRC(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetRepositoriesIRC <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){
    fields = " COUNT(DISTINCT(channel_id)) AS repositories "
    tables = paste(" irclog ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(q))
}

EvolRepositoriesIRC <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetRepositoriesIRC(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetTopSendersIRC <- function(days = 0, startdate, enddate, identities_db, bots, limit) {
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
    q <- paste("SELECT up.id as id, up.identifier as senders,
                    count(irclog.id) as sent
                FROM irclog, people_upeople pup, ",identities_db,".upeople up
                WHERE ", filter_bots, "
                    irclog.type = 'COMMENT' and
                    irclog.nick = pup.people_id and
                    pup.upeople_id = up.id and
                    date >= ", startdate, " and
                    date  < ", enddate, " ", date_limit, "
                    GROUP BY senders
                    ORDER BY sent desc
                    LIMIT ",limit ,";", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#
# Repositories (channels)
#

GetTablesReposIRC <- function () {
    return (paste(GetTablesOwnUniqueIdsIRC(),",channels c"))
}

GetFiltersReposIRC <- function () {
    filters = paste(GetFiltersOwnUniqueIdsIRC(),
            "AND c.id = irclog.channel_id")    
    return(filters)    
}

GetReposNameIRC <- function() {
    q <- "SELECT name, count(i.id) AS total
          FROM irclog i, channels c
          WHERE i.channel_id=c.id
          GROUP BY name ORDER BY total DESC"
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data$name)
}

GetRepoEvolSentSendersIRC <- function(repo, period, startdate, enddate){    
    fields = 'COUNT(irclog.id) AS sent, 
              COUNT(DISTINCT(pup.upeople_id)) AS senders'
    tables= GetTablesReposIRC()
    filters = paste(GetFiltersReposIRC()," AND c.name='",repo,"'",sep="")
    filters <- paste(filters, "AND irclog.type='COMMENT' ", sep="")    
    q <- GetSQLPeriod(period,'date', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoStaticSentSendersIRC <- function (repo, startdate, enddate) {
    fields = 'COUNT(irclog.id) AS sent, 
              COUNT(DISTINCT(pup.upeople_id)) AS senders'
    tables = GetTablesReposIRC()
    filters = paste(GetFiltersReposIRC()," AND c.name='",repo,"'",sep="")
    filters <- paste(filters, "AND irclog.type='COMMENT' ", sep="")
    q <- GetSQLGlobal('date',fields, tables, filters, startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#########
# PEOPLE
#########
GetListPeopleIRC <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id, count(irclog.id) total"
    tables = GetTablesOwnUniqueIdsIRC()
    filters = GetFiltersOwnUniqueIdsIRC()
    filters <- paste(filters, "AND irclog.type='COMMENT' ", sep="")
    filters = paste(filters,"GROUP BY nick ORDER BY total desc")
    q = GetSQLGlobal('date',fields,tables, filters, startdate, enddate)
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

GetQueryPeopleIRC <- function(developer_id, period, startdate, enddate, evol) {
    fields = "COUNT(irclog.id) AS sent"
    tables = GetTablesOwnUniqueIdsIRC()
    filters = paste(GetFiltersOwnUniqueIdsIRC(), "AND pup.upeople_id = ", developer_id)
    filters <- paste(filters, " AND irclog.type='COMMENT' ", sep="")

    if (evol) {
        q = GetSQLPeriod(period,'date', fields, tables, filters,
                startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(date),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(date),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('date', fields, tables, filters,
                startdate, enddate)
    }
    return (q)
}

GetEvolPeopleIRC <- function(developer_id, period, startdate, enddate) {
    q <- GetQueryPeopleIRC(developer_id, period, startdate, enddate, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticPeopleIRC <- function(developer_id, startdate, enddate) {
    q <- GetQueryPeopleIRC(developer_id, period, startdate, enddate, FALSE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

##############
# Microstudies
##############

GetIRCDiffSentDays <- function(period, init_date, days){
    # This function provides the percentage in activity between two periods.
    #
    # The netvalue indicates if this is an increment (positive value) or decrement (negative value)

    chardates = GetDates(init_date, days)
    lastmessages = StaticNumSentIRC(period, chardates[2], chardates[1])
    lastmessages = as.numeric(lastmessages[1])
    prevmessages = StaticNumSentIRC(period, chardates[3], chardates[2])
    prevmessages = as.numeric(prevmessages[1])
    diffmessagesdays = data.frame(diff_netmessages = numeric(1), percentage_messages = numeric(1))

    diffmessagesdays$diff_netmessages = lastmessages - prevmessages
    diffmessagesdays$percentage_messages = GetPercentageDiff(prevmessages, lastmessages)
    diffmessagesdays$lastmessages = lastmessages

    colnames(diffmessagesdays) <- c(paste("diff_netsent","_",days, sep=""), 
                                    paste("percentage_sent","_",days, sep=""),
                                    paste("sent","_",days, sep=""))

    return (diffmessagesdays)
}


GetIRCDiffSendersDays <- function(period, init_date, identities_db=NA, days){
    # This function provides the percentage in activity between two periods:
    # Fixme: equal to GetDiffAuthorsDays

    chardates = GetDates(init_date, days)
    lastsenders = StaticNumSendersIRC(period, chardates[2], chardates[1], identities_db)
    lastsenders = as.numeric(lastsenders[1])
    prevsenders = StaticNumSendersIRC(period, chardates[3], chardates[2], identities_db)
    prevsenders = as.numeric(prevsenders[1])
    diffsendersdays = data.frame(diff_netsenders = numeric(1), percentage_senders = numeric(1))
    diffsendersdays$diff_netsenders = lastsenders - prevsenders
    diffsendersdays$percentage_senders = GetPercentageDiff(prevsenders, lastsenders)
    diffsendersdays$lastsenders = lastsenders

    colnames(diffsendersdays) <- c(paste("diff_netsenders","_",days, sep=""), 
                                   paste("percentage_senders","_",days, sep=""),
                                   paste("senders","_",days, sep=""))
    return (diffsendersdays)
}

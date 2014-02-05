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
## MediaWiki.R
##
## Queries for source code review data analysis
##
## Authors:
##   Alvaro del Castillo <acs@bitergia.com>

# SQL Metaqueries

GetTablesOwnUniqueIdsMediaWiki <- function() {
    tables = 'wiki_pages_revs, people_upeople pup'
    return (tables)
}

GetFiltersOwnUniqueIdsMediaWiki <- function () {
    filters = 'pup.people_id = wiki_pages_revs.user'
    return (filters) 
}

# GLOBAL

GetStaticDataMediaWiki <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){
    # 1- Retrieving information
    reviews <- StaticNumReviewsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    authors <- StaticNumAuthorsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    pages <- StaticPagesMediaWiki(period, startdate, enddate, i_db, type_analysis)

    # 2- Merging information
    static_data = merge(reviews, authors)
    static_data = merge(static_data, pages)

    return (static_data)
}

GetEvolDataMediaWiki <- function(period, startdate, enddate, i_db=NA, type_analysis=list(NA, NA)){

    # 1- Retrieving information
    reviews <- EvolReviewsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    authors <- EvolAuthorsMediaWiki(period, startdate, enddate, i_db, type_analysis)
    pages <- EvolPagesMediaWiki(period, startdate, enddate)

    # 2- Merging information
    evol_data = merge(reviews, authors, all = TRUE)
    evol_data = merge(evol_data, pages, all = TRUE)

    return (evol_data)
}

StaticNumReviewsMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(rev_id) as reviews,
               DATE_FORMAT (min(date), '%Y-%m-%d') as first_date,
               DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    from <- " FROM wiki_pages_revs "
    where <- paste(" where date >=", startdate, " and
                     date < ", enddate, sep="")
    q <- paste(select, from, where)
    return(ExecuteQuery(q))
}

StaticNumAuthorsMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {    
    select <- "SELECT count(distinct(user)) as authors"
    from <- " FROM wiki_pages_revs "
    where <- paste(" where date >=", startdate, " and
                    date < ", enddate, sep="")
    q <- paste(select, from, where)    
    return(ExecuteQuery(q))
}




GetQueryPagesMediaWiki <- function(period, startdate, enddate, evol) {
    fields <- "COUNT(page_id) as pages"
    tables <- " (
            SELECT wiki_pages.page_id, MIN(date) as date FROM wiki_pages, wiki_pages_revs
            WHERE wiki_pages.page_id=wiki_pages_revs.page_id 
            GROUP BY wiki_pages.page_id) t "
    filters <- ''

    if (evol) {
            q = GetSQLPeriod(period,'date', fields, tables, filters,
                            startdate, enddate)
    } else {
            q = GetSQLGlobal('date', fields, tables, filters,
                            startdate, enddate)
    }
    return(q)
}


StaticPagesMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    q <- GetQueryPagesMediaWiki(period, startdate, enddate, FALSE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

EvolPagesMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis=list(NA, NA)) {
    q <- GetQueryPagesMediaWiki(period, startdate, enddate, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetReviewsMediaWiki <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){    
    fields = " count(distinct(rev_id)) as reviews "
    tables = paste(" wiki_pages_revs ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")    
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))
}

EvolReviewsMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetReviewsMediaWiki(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetAuthorsMediaWiki <- function(period, startdate, enddate, identities_db, type_analysis, evolutionary){    
    fields = " count(distinct(user)) as authors "
    tables = paste(" wiki_pages_revs ", GetSQLReportFrom(identities_db, type_analysis))
    filters = GetSQLReportWhere(type_analysis, "author")
    q <- BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)    
    return(ExecuteQuery(q))
}

EvolAuthorsMediaWiki <- function(period, startdate, enddate, identities_db=NA, type_analysis = list(NA, NA)){
    return(GetAuthorsMediaWiki(period, startdate, enddate, identities_db, type_analysis, TRUE))
}

GetTopAuthorsMediaWiki <- function(days = 0, startdate, enddate, identities_db, bots, limit) {
    date_limit = ""
    filter_bots = ''
    for (bot in bots){
        filter_bots <- paste(filter_bots, " user<>'",bot,"' and ",sep="")
    }
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(date) from wiki_pages_revs limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, date)<",days)
    }
    q <- paste("SELECT up.id as id, up.identifier as authors,
                    count(wiki_pages_revs.id) as reviews
                FROM wiki_pages_revs, people_upeople pup, ",identities_db,".upeople up
                WHERE ", filter_bots, "
                    wiki_pages_revs.user = pup.people_id and
                    pup.upeople_id = up.id and
                    date >= ", startdate, " and
                    date  < ", enddate, " ", date_limit, "
                    GROUP BY authors
                    ORDER BY reviews desc, authors
                    LIMIT ",limit ,";", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#########
# PEOPLE
#########
GetListPeopleMediaWiki <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id, count(wiki_pages_revs.id) total"
    tables = GetTablesOwnUniqueIdsMediaWiki()
    filters = GetFiltersOwnUniqueIdsMediaWiki()
    filters = paste(filters,"GROUP BY user ORDER BY total desc")
    q = GetSQLGlobal('date',fields,tables, filters, startdate, enddate)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetQueryPeopleMediaWiki <- function(developer_id, period, startdate, enddate, evol) {
    fields = "COUNT(wiki_pages_revs.id) AS revisions"
    tables = GetTablesOwnUniqueIdsMediaWiki()
    filters = paste(GetFiltersOwnUniqueIdsMediaWiki(), "AND pup.upeople_id = ", developer_id)

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

GetEvolPeopleMediaWiki <- function(developer_id, period, startdate, enddate) {
    q <- GetQueryPeopleMediaWiki(developer_id, period, startdate, enddate, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticPeopleMediaWiki <- function(developer_id, startdate, enddate) {
    q <- GetQueryPeopleMediaWiki(developer_id, period, startdate, enddate, FALSE)
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}


###############
# Last Activity
###############
lastActivityMediaWiki <- function(init_date, days) {
    #commits
    q <- paste("select count(wiki_pages_revs.id) as reviews_",days,"
                from wiki_pages_revs
                where date >= (", init_date, " - INTERVAL ",days," day)",
            sep="")

    query <- new("Query", sql = q)
    data1 = run(query)
    q <- paste("select count(distinct(pup.upeople_id)) as authors_",days,"
                from wiki_pages_revs, people_upeople pup
                where pup.people_id = user  and
                  date >= (", init_date, " - INTERVAL ",days," day)",
            sep="")

    query <- new("Query", sql = q)
    data2 = run(query)

    agg_data = merge(data1, data2)

    return(agg_data)
}

##############
# Microstudies
##############

GetMediaWikiDiffReviewsDays <- function(period, init_date, days){
    # This function provides the percentage in activity between two periods.
    #
    # The netvalue indicates if this is an increment (positive value) or decrement (negative value)

    chardates = GetDates(init_date, days)
    lastreviews = StaticNumReviewsMediaWiki(period, chardates[2], chardates[1])
    lastreviews = as.numeric(lastreviews[1])
    prevreviews = StaticNumReviewsMediaWiki(period, chardates[3], chardates[2])
    prevreviews = as.numeric(prevreviews[1])
    diffreviewsdays = data.frame(diff_netreviews = numeric(1), percentage_reviews = numeric(1))

    diffreviewsdays$diff_netreviews = lastreviews - prevreviews
    diffreviewsdays$percentage_reviews = GetPercentageDiff(prevreviews, lastreviews)
    diffreviewsdays$lastreviews = lastreviews

    colnames(diffreviewsdays) <- c(paste("diff_netreviews","_",days, sep=""), 
                                   paste("percentage_reviews","_",days, sep=""),
                                   paste("reviews","_",days, sep=""))

    return (diffreviewsdays)
}


GetMediaWikiDiffAuthorsDays <- function(period, init_date, identities_db=NA, days){
    # This function provides the percentage in activity between two periods:
    # Fixme: equal to GetDiffAuthorsDays

    chardates = GetDates(init_date, days)
    lastauthors = StaticNumAuthorsMediaWiki(period, chardates[2], chardates[1], identities_db)
    lastauthors = as.numeric(lastauthors[1])
    prevauthors = StaticNumAuthorsMediaWiki(period, chardates[3], chardates[2], identities_db)
    prevauthors = as.numeric(prevauthors[1])
    diffauthorsdays = data.frame(diff_netauthors = numeric(1), percentage_authors = numeric(1))
    diffauthorsdays$diff_netauthors = lastauthors - prevauthors
    diffauthorsdays$percentage_authors = GetPercentageDiff(prevauthors, lastauthors)
    diffauthorsdays$lastauthors = lastauthors

    colnames(diffauthorsdays) <- c(paste("diff_netauthors","_",days, sep=""), 
                                   paste("percentage_authors","_",days, sep=""),
                                   paste("authors","_",days, sep=""))

    return (diffauthorsdays)

}

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
##
## Usage:
##  R --no-restore --no-save < its-milestone0.R
## or
##  R CMD BATCH its-milestone0.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
## conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
##                            user = "root", password = NULL,
##                            host = "127.0.0.1", port = 3308)
## SetDBChannel (database = conf$database,
##               user = conf$user, password = conf$password,
##               host = conf$host, port = conf$port)
conf <- ConfFromParameters(dbschema = "kdevelop_bicho", user = "jgb", password = "XXX")
SetDBChannel (database = conf$database, user = conf$user, password = conf$password)

its <- "bugzilla"

closed_condition <- "new_value='RESOLVED' OR new_value='CLOSED'"

if (its == 'allura') closed_condition <- "new_value='CLOSED'"
if (its == 'github') closed_condition <- "field='closed'"

# Closed tickets: time ticket was open, first closed, time-to-first-close
q <- paste("SELECT issue_id, issue,
        submitted_on as time_open,
        time_closed,
    time_closed_last,
    TIMESTAMPDIFF (DAY, submitted_on, ch.time_closed) AS ttofix
      FROM issues, (
         SELECT
           issue_id,
           MIN(changed_on) AS time_closed,
           MAX(changed_on) as time_closed_last
         FROM changes
         WHERE ",closed_condition,"
         GROUP BY issue_id) ch
      WHERE issues.id = ch.issue_id")
query <- new ("Query", sql = q)
res_issues_closed <- run(query)

# Opened and openers
q <- paste ("SELECT year(submitted_on) * 12 + month(submitted_on) AS id,
               year(submitted_on) AS year,
               month(submitted_on) AS month,
	       DATE_FORMAT (submitted_on, '%b %Y') as date,
               count(submitted_by) AS opened,
               count(distinct(submitted_by)) AS openers
             FROM issues
	     GROUP BY year,month
	     ORDER BY year,month")
query <- new ("Query", sql = q)
open_monthly <- run(query)

# Closed and closers
q <- paste ("SELECT year(changed_on) * 12 + month (changed_on) AS id,
               year(changed_on) as year,
               month(changed_on) as month,
               DATE_FORMAT (changed_on, '%b %Y') as date,
               count(issue_id) AS closed,
               count(distinct(changed_by)) AS closers
             FROM changes
             WHERE ",closed_condition," 
             GROUP BY year,month
         ORDER BY year,month")
query <- new ("Query", sql = q)
closed_monthly <- run(query)

# Changed and changers 
q <- paste ("SELECT year(changed_on) * 12 + month (changed_on) AS id,
               year(changed_on) as year,
               month(changed_on) as month,
           DATE_FORMAT (changed_on, '%b %Y') as date,
               count(changed_by) AS changed,
               count(distinct(changed_by)) AS changers
             FROM changes
             GROUP BY year,month
         ORDER BY year,month")
query <- new ("Query", sql = q)
changed_monthly <- run(query)

issues_monthly <- merge (open_monthly, closed_monthly, all = TRUE)
issues_monthly <- merge (issues_monthly, changed_monthly, all = TRUE)
issues_monthly[is.na(issues_monthly)] <- 0

issues_monthly <- completeZeroMonthly(issues_monthly)

createJSON (issues_monthly, "its-milestone0.json")

## Get some general stats from the database
##
q <- paste ("SELECT count(*) as tickets,
			 count(distinct(submitted_by)) as openers,
			 DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
			 DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date 
			 FROM issues")
query <- new ("Query", sql = q)
data <- run(query)
q <- paste ("SELECT count(distinct(changed_by)) as closers FROM changes WHERE ",
            closed_condition)
query <- new ("Query", sql = q)
data1 <- run(query)
q <- "SELECT count(distinct(changed_by)) as changers FROM changes"
query <- new ("Query", sql = q)
data2 <- run(query)
q <- "SELECT count(*) as opened FROM issues"
query <- new ("Query", sql = q)
data3 <- run(query)
q <- "SELECT count(distinct(issue_id)) as changed FROM changes"
query <- new ("Query", sql = q)
data4 <- run(query)
q <- paste ("SELECT count(distinct(issue_id)) as closed FROM changes WHERE",
            closed_condition)
query <- new ("Query", sql = q)
data5 <- run(query)
agg_data = merge(data, data1)
agg_data = merge(agg_data, data2)
agg_data = merge(agg_data, data3)
agg_data = merge(agg_data, data4)
agg_data = merge(agg_data, data5)
createJSON (agg_data, "its-info-milestone0.json")

## Top closers
top_closers_data <- list()
top_closers_data[['closers.']]<-top_closers(closed_condition = closed_condition)
top_closers_data[['closers.last year']]<-top_closers(days = 365,
                                                     closed_condition = closed_condition)
top_closers_data[['closers.last month']]<-top_closers(days = 31,
                                                      closed_condition = closed_condition)

createJSON (top_closers_data, "its-top-milestone0.json")

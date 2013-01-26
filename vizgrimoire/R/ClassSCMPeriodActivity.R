## Copyright (C) 2012 Bitergia
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
##
## SCMPeriodActivity class
##
## Class for handling activity per developer for a certain period
##

## FIXME: Still wirting it, based in ITSMonthly

## Query for getting activity per author for a given period
## (format string, first %s is starting date for the period
## (period >= date), second % is the final date (period<date).
## Date in the "2013-01-26" format.
##
format.query <- "SELECT 
    author_id as id, people.name as name, people.email as email,
    count(scmlog.id) as actions,
    MIN(scmlog.date) as firstdatestr, MAX(scmlog.date) as lastdatestr
FROM
    scmlog, people
WHERE
    scmlog.author_id = people.id AND
    scmlog.date >= %s AND
    scmlog.date < %s
GROUP by author_id"

## Query for getting activity per author for a given period
## (format string, first %s is starting date for the period
## (period >= date), second % is the final date (period<date).
## Date in the "2013-01-26" format.
## Uses upeople table to consider unique identities.
##
format.query.unique = "SELECT 
    upeople.uid as id,
    people.name as name,
    people.email as email,
    count(scmlog.id) as actions,
    MIN(scmlog.date) as firstdatestr,
    MAX(scmlog.date) as lastdatestr
FROM
    scmlog,
    people,
    upeople
where
    scmlog.author_id = upeople.id AND
    people.id = upeople.id AND
    scmlog.date >= %s AND
    scmlog.date < %s
group by upeople.uid"

setClass(Class="SCMPeriodActivity",
         contains="data.frame",
         )

##
## Initialize, by running the query for the object
##  and returning the corresponding data frame.
##
## Rows produced by the query should include one called "id",
##  which must be, for each month, year*12+month, as integer
##
## Initialization fills in missing months, and adds some columns:
##  - year (as integer, XXXX)
##  - month (as integer, 1-12)
##  - date (as text, eg: "Feb 2012")
##
setMethod(f="initialize",
          signature="SCMPeriodActivity",
          definition=function(.Object, start = "1900-01-01",
                              finish = "2100-01-01",
                              unique = FALSE, query = NULL){
            cat("~~~ SCMPeriodActivity: initializator ~~~ \n")
            if (!is.null(query)) {
              ## We have a query, forget about unique
              q <- new ("Query", sql = sprintf (query, start, date))
            } else if (unique) {
              q <- new ("Query",
                        sql = sprintf (format.query.unique, start, date))
            } else {
              q <- new ("Query", sql = sprintf (format.query, start, date))
            }
            as(.Object,"data.frame") <- run (q)
            ## Complete months not present
            as(.Object,"data.frame") <- completeZeroMonthly (run (q))
            .Object$year <- (.Object$id - 1) %/% 12
            .Object$month <- ((.Object$id - 1) %% 12) + 1
            .Object$date <- toTextDate(.Object$year, .Object$month)
            return(.Object)
          }
          )


setMethod(
  f="JSON",
  signature="SCMPeriodActivity",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(.Object))
    sink()
  }
  )

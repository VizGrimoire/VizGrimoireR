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
## This file is a part of the vizgrimoire R package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
##
## Demographics class
##
## Class for handling demographics about developers
##

## Query for getting first and last date in scmlog for all authors in scmlog
##
query.scm <- "SELECT author_id as id,
                     people.name as name,
                     people.email as email,
                     count(scmlog.id) as actions,
                     MIN(scmlog.date) as firstdatestr,
                     MAX(scmlog.date) as lastdatestr
              FROM
                     scmlog, people
              WHERE
                     scmlog.author_id = people.id
             GROUP by author_id"

## Query for getting first and last date in scmlog for all authors in scmlog,
## when upeople table (unique identities) is available
##

query.scm.unique <- "SELECT 
    upeople.uid as id,
    people.name as name,
    people.email as email,
    count(scmlog.id) as actions,
    MIN(scmlog.date) as firstdatestr,
    MAX(scmlog.date) as lastdatestr
FROM
    scmlog, people, upeople
WHERE
    scmlog.author_id = upeople.id AND
    people.id = upeople.id
GROUP BY upeople.uid"

## Query for getting first and last date for all senders in a MLS database
##
query.mls <- "SELECT people.email_address as id,
                     people.name as name,
                     people.email_address as email,
                     MIN(first_date) as firstdatestr,
                     MAX(first_date) as lastdatestr
              FROM messages, messages_people, people
              WHERE messages.message_ID = messages_people.message_id
                    AND people.email_address = messages_people.email_address
                    AND messages_people.type_of_recipient = \"From\"
              GROUP BY people.email_address"

## Query to get first and last date for all people in an ITS (Bicho)
##  database (changes table)
##
query.its <- "SELECT changes.changed_by as id,
                     people.name as name,
                     people.email as email,
                     COUNT(changes.id) as actions,
                     MIN(changes.changed_on) as firstdatestr,
                     MAX(changes.changed_on) as lastdatestr
              FROM changes, people
              WHERE changes.changed_by = people.id
              GROUP BY changes.changed_by"

## Build an SQL query to get people active since months ago.
##
## Returns a query to get all records produced by a "first and last date" query
##  which include a lastdate larger than months before now
## Returned queries are like
##  SELECT * FROM ( .... ) mytable
##  WHERE mytable.lastdatestr > SUBDATE(NOW(), INTERVAL 4 MONTH)
## Arguments: query and number of months for intervals
##
build.query <- function (query, months) {
    q <- paste("SELECT * FROM ( ", query, ") mytable
                WHERE mytable.lastdatestr > SUBDATE(NOW(), INTERVAL ",
                months," MONTH)")
    return(q)
}

## Declaring Demographics class
##

setClass(Class="Demographics",
         contains="data.frame",
         )

## Initialize it by storing the options that will be used later
setMethod(f="initialize",
          signature="Demographics",
          definition=function(.Object, type, months, unique = FALSE, query = NULL){
              cat("~~~ Demographics: initializator ~~~ \n")
              attr(.Object, 'type') <- type
              attr(.Object, 'months') <- months
              attr(.Object, 'unique') <- unique
              if (type == 'scm') {
                  cat("~~~ SCM query\n")
                  if (unique) {
                      sql <- query.scm.unique
                  } else {
                      sql <- query.scm
                  }
              } else if (type == 'mls') {
                  cat("~~~ MLS query\n")
                  sql <- query.mls
              } else if (type == 'its') {
                  cat("~~~ ITS query\n")
                  sql <- query.its
              }
              q <- new("Query", sql = sql)
              ## Attr activity is a dataframe with a row per person,
              ##  each row has its date for first and last activity,
              ##  and the staying time in the repo (in days)
              ## Dates have to be formated properly
              activity <- run (q)
              activity$firstdate <- strptime(activity$firstdatestr,
                                             format="%Y-%m-%d %H:%M:%S")
              activity$lastdate <- strptime(activity$lastdatestr,
                                            format="%Y-%m-%d %H:%M:%S")
              activity$stay <- round (as.numeric(
                  difftime(activity$lastdate,
                           activity$firstdate,
                           units="days"))) 
              attr(.Object, 'activity') <- activity
              return(.Object)
          })

##
## Generic Aging function
##
setGeneric (
  name= "Aging",
  def=function(.Object){standardGeneric("Aging")}
  )

##
## Get activity data for persons still active in a Demographics object
##
## Returns a dataframe which is the activity attr of the objcet
## It includes one row per person, with dated for first and last activity,
##  and the staying time in the repo (in days), for those that are still
##  active duirng the last .Object@months.
setMethod(f="Aging",
          signature="Demographics",
          definition=function(.Object){
            cat("~~~ Demographics - Aging ~~~ \n")
            currenttime <- strptime(Sys.time(), format="%Y-%m-%d %H:%M:%S")
            active <- subset (attr (.Object, 'activity'),
                      floor(as.numeric(difftime(currenttime, lastdate,
                                                units="days"))) <=
                              attr (.Object, 'months') * 30)
            active$left <- floor(as.numeric(difftime(currenttime, active$lastdate,
                                                units="days")))
            return(active)
          }
          )

##
setGeneric (
  name= "Birth",
  def=function(.Object){standardGeneric("Birth")}
  )

##
setMethod(f="Birth",
          signature="Demographics",
          definition=function(.Object){
            cat("~~~ Demographics - Birth ~~~ \n")
            
            
            res <- run (q)
            res$firstdate <- strptime(res$firstdatestr,
                                      format="%Y-%m-%d %H:%M:%S")
            res$lastdate <- strptime(res$firstdatestr,
                                     format="%Y-%m-%d %H:%M:%S")
            return(res)
          }
          )


##
## Create a JSON file out of an object of this class
##
## Parameters:
##  - filename: name of the JSON file to write
##
setMethod(
  f="JSON",
  signature="Demographics",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(demography=as.data.frame(.Object))))
    sink()
  }
  )


##
## Generic GetAges function
##
setGeneric (
  name= "GetAges",
  def=function(.Object,...){standardGeneric("GetAges")}
  )
##
## Ages of developers for a certain date
##
## - date: date as string (eg: "2010-01-01")
## - normalize.by: number of days to add to each age (or NULL
##    for no normalization)
## Value: an Ages object
##
setMethod(
  f="GetAges",
  signature="Demographics",
  definition=function(.Object, date, normalize.by = NULL) {

    active <- subset (as.data.frame (.Object),
                      firstdate <= strptime(date, format="%Y-%m-%d") &
                      lastdate >= strptime(date, format="%Y-%m-%d"))
    age <- round (as.numeric (difftime (strptime(date, format="%Y-%m-%d"),
                                        active$firstdate, units="days")))
    if (is.null(normalize.by)) {
      normalization <- 0
    } else {
      normalization <- normalize.by
    }
    ages <- new ("Ages", date=date,
                 id = active$id, name = active$name, email = active$email,
                 age = age + normalization)
    return (ages)
  }
  )

##
## Generic GetActivity function
##
setGeneric (
  name= "GetActivity",
  def=function(.Object,...){standardGeneric("GetActivity")}
  )
##
## Activity (no. of commits) of developers for a certain period before a time
##
## - time: end date of the period, as string (eg: "2013-01-26")
## - period: number of days for the period to consider
## - unique: consider upeople table for unique identities
##
## Value: a SCMPeriodActivity object
##
setMethod(
  f="GetActivity",
  signature="Demographics",
  definition=function(.Object, time = "1900-01-01",
                      period,
                      unique = FALSE) {
    activity <- new ("SCMPeriodActivity",
                     as.Date(time) - period, time, unique)
    return (activity)
  }
  )

##
## Generic ProcessAges function
##
setGeneric (
  name= "ProcessAges",
  def=function(.Object,...){standardGeneric("ProcessAges")}
  )
##
## ProcessAges
## Produce information and charts for ages based on a Demographics
##  object at a certain date
##
## - date: date at which we consider the time cut
## - filename: name (prefix) of files produced
## - periods: periods per year (1: year, 4: quarters, 12: months)
## Value: Ages obect for that time cut
##
## For the given date, an ages object is produced, with it as date cut.
## Produces:
##  - JSON file with ages
##  - Chart of a demographic pyramid
##
setMethod(
  f="ProcessAges",
  signature="Demographics",
  definition=function(.Object, date, filename, periods=4) {
    ages <- GetAges (.Object, date)
    JSON (ages, paste(c(filename, date, ".json"), collapse = ""))
    Pyramid (ages, paste(c(filename, date), collapse = ""), 4)
    return (ages)
  }
  )

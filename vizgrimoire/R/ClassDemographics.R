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

query.scm <- "SELECT 
    author_id as id, people.name as name, people.email as email,
    count(scmlog.id) as actions,
    MIN(scmlog.date) as firstdatestr, MAX(scmlog.date) as lastdatestr
FROM
    scmlog, people
WHERE
    scmlog.author_id = people.id
GROUP by author_id"


setClass(Class="Demographics",
         contains="data.frame",
         )
## Initialize by running the query that gets dates for population,
## and by initializing the data frames with specialized data
##
setMethod(f="initialize",
          signature="Demographics",
          definition=function(.Object, query = query.scm){
            cat("~~~ Demographics: initializator ~~~ \n")
            q <- new ("Query", sql = query)
            as(.Object,"data.frame") <- run (q)
            .Object$firstdate <- strptime(.Object$firstdatestr,
                                          format="%Y-%m-%d %H:%M:%S")
            .Object$lastdate <- strptime(.Object$lastdatestr,
                                         format="%Y-%m-%d %H:%M:%S")
            .Object$stay <- round (as.numeric(
                                     difftime(.Object$lastdate,
                                              .Object$firstdate,
                                              units="days")))            
            return(.Object)
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

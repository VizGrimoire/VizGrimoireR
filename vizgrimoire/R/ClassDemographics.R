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
    MIN(scmlog.date) as firstdate, MAX(scmlog.date) as lastdate
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
          definition=function(.Object){
            cat("~~~ Demographics: initializator ~~~ \n")
            q <- new ("Query", sql = query.scm)
            as(.Object,"data.frame") <- run (q)
            .Object$firstdate <- strptime(periods$firstdate,
                                          format="%Y-%m-%d %H:%M:%S")
            .Object$lastdate <- strptime(periods$lastdate,
                              format="%Y-%m-%d %H:%M:%S")
            .Object$stay <- round (as.numeric(
                                     difftime(periods$lastdate,
                                              periods$firstdate,
                                              units="days")))            
            return(.Object)
          }
          )

##
## Create a JSON file out of a ITSTicketsTimes object
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

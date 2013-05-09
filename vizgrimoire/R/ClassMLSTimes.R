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
##   Luis Cañas-Díaz <lcanas@bitergia.com>
##
##
## MLSTimes class
##
## Class for handling the many times of each thread
##  (open, replied so far)
##

query.pre = "
CREATE TEMPORARY TABLE replies AS (
SELECT is_response_of, MIN(arrival_date) as firstreply, MAX(arrival_date) AS lastreply
FROM messages
WHERE message_ID <> is_response_of
AND subject <> message_body
GROUP BY is_response_of);"

query.replied = "
SELECT m.message_ID, m.arrival_date as submitted_on, rep.firstreply, rep.lastreply
FROM messages m
JOIN replies rep
ON m.message_ID = rep.is_response_of
WHERE m.message_ID = m.is_response_of
AND m.subject <> m.message_body
ORDER BY submitted_on ASC"

setClass(Class="MLSTimes",
         contains="data.frame",
         )
## Initialize by running the query that gets times for each thread,
## and by initializing the data frames with specialized data
## (only time to reply first so far)
setMethod(f="initialize",
          signature="MLSTimes",
          definition=function(.Object){
            cat("~~~ MLSTimes: initializator ~~~ \n")
            print (conf)
            q0 <- new ("Query", sql = query.pre)
            run (q0)
            q <- new ("Query", sql = query.replied)
            as(.Object,"data.frame") <- run (q)
            .Object$submitted_on <- strptime(.Object$submitted_on,
                                     format="%Y-%m-%d %H:%M:%S")
            .Object$firstreply <- strptime(.Object$firstreply,
                                       format="%Y-%m-%d %H:%M:%S")
            .Object$toattend <- round (as.numeric(
                                      difftime(.Object$firstreply,
                                               .Object$submitted_on,
                                               units="secs")
                                      ))
            return(.Object)
          }
          )

##
## Create a JSON file out of a MLSTimes object
##
## Parameters:
##  - filename: name of the JSON file to write
##
setMethod(
  f="JSON",
  signature="MLSTimes",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(tickets=as.data.frame(.Object))))
    sink()
  }
  )


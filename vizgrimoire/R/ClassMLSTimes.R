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
##   Alvaro del Castillo <acs@bitergia.com>
##
##
## MLSTimes class
##
## Class for handling the many times of each thread
##  (open, replied so far)
##

liferay = FALSE

query.pre = "
CREATE TEMPORARY TABLE replies AS (
 SELECT is_response_of, MIN(UNIX_TIMESTAMP(first_date)-first_date_tz) as firstreply, MAX(UNIX_TIMESTAMP(first_date)-first_date_tz) AS lastreply
 FROM messages
 WHERE "

if (liferay) {
    query.pre = paste(query.pre,"message_ID <> is_response_of")
} else {
    query.pre = paste(query.pre,"is_response_of IS NOT NULL")
}
query.pre = paste(query.pre, "GROUP BY is_response_of);")

query.replied = "
SELECT m.message_ID, m.first_date as submitted_on,
 (UNIX_TIMESTAMP(m.first_date)-first_date_tz) as submitted_on_stamp, rep.firstreply, rep.lastreply
 FROM messages m
 JOIN replies rep
 ON m.message_ID = rep.is_response_of
 WHERE "

if (liferay) {
      query.replied = paste(query.replied,"m.message_ID = m.is_response_of")
} else {
    query.replied = paste(query.replied,"m.is_response_of IS NULL")
}
query.replied = paste(query.replied, "ORDER BY submitted_on ASC")

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
            # print (conf)
            q0 <- new ("Query", sql = query.pre)
            run (q0)
            q <- new ("Query", sql = query.replied)
            as(.Object,"data.frame") <- run (q)
            .Object$toattend <- .Object$firstreply - .Object$submitted_on_stamp                   
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


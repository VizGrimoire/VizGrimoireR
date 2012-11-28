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
## ITSTicketsChangesTimes class
##
## Class for handling the many times of the changes to each ticket
##

query.changed <- "SELECT 
    issue_id as id,
    issue,
    issues.submitted_on as open,
    MIN(ch.time_first) AS first,
    MIN(ch.time_last) AS last
FROM
    issues,
    (SELECT 
        issue_id,
            MIN(changed_on) AS time_first,
            MAX(changed_on) AS time_last
    FROM
        changes
    GROUP BY issue_id UNION SELECT 
        issue_id,
            MIN(submitted_on) AS time_first,
            MAX(submitted_on) AS time_last
    FROM
        comments
    GROUP BY issue_id) ch
WHERE
    issues.id = ch.issue_id
GROUP BY issue_id
ORDER BY issue_id"

setClass(Class="ITSTicketsChangesTimes",
         contains="data.frame",
         )
## Initialize by running the query that gets times for each ticket
## related to when it was first changed
setMethod(f="initialize",
          signature="ITSTicketsChangesTimes",
          definition=function(.Object){
            cat("~~~ ITSTicketsChangesTimes: initializator ~~~ \n")
            q <- new ("QueryTimeSerie", sql = query.changed)
            as(.Object,"data.frame") <- run (q)
            .Object$open <- strptime(.Object$open,
                                     format="%Y-%m-%d %H:%M:%S")
            .Object$first <- strptime(.Object$first,
                                      format="%Y-%m-%d %H:%M:%S")
            .Object$last <- strptime(.Object$last,
                                     format="%Y-%m-%d %H:%M:%S")
            .Object$toattention <- round (as.numeric(
                                            difftime(.Object$first,
                                                     .Object$open,
                                                     units="secs")
                                      ))
            .Object$tolastmove <- round(as.numeric(
                                          difftime(.Object$last,
                                                   .Object$open,
                                                   units="secs")
                                          ))
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
  signature="ITSTicketsChangesTimes",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(tickets=as.data.frame(.Object))))
    sink()
  }
  )


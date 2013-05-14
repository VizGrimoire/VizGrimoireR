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
## ITSTicketsTimes class
##
## Class for handling the many times of each ticket
##  (open, closed, changed, etc.)
##

query.closed = c (
  "bugzilla" = "SELECT issue_id as id,
        issue,
     	submitted_on AS open,
        closed,
	closedlast
      FROM issues, (
         SELECT
           issue_id,
           MIN(changed_on) AS closed,
           MAX(changed_on) AS closedlast
         FROM changes
         WHERE (new_value='RESOLVED' OR new_value='CLOSED')
         GROUP BY issue_id) ch
      WHERE issues.id = ch.issue_id
      ORDER BY submitted_on",
  "allura" = "SELECT issue_id as id,
        issue,
     	submitted_on AS open,
        closed,
	        closedlast
              FROM issues, (
        SELECT
        issue_id,
        MIN(changed_on) AS closed,
        MAX(changed_on) AS closedlast
        FROM changes
        WHERE (new_value='CLOSED')
        GROUP BY issue_id) ch
              WHERE issues.id = ch.issue_id
              ORDER BY submitted_on",
  "jira" = "SELECT issue_id as id,
        issue,
     	submitted_on AS open,
        closed,
	closedlast
      FROM issues, (
         SELECT
           issue_id,
           MIN(changed_on) AS closed,
           MAX(changed_on) AS closedlast
         FROM changes
         WHERE new_value IN ('Expired', 'Fixed', 'Invalid',
                             'Opinion', 'Won''t Fix')
         GROUP BY issue_id) ch
      WHERE issues.id = ch.issue_id
      ORDER BY submitted_on",
    "launchpad" = "SELECT issue_id as id,
                          issue,
                          submitted_on AS open,
                          closed,
                          closedlast
                   FROM issues,
                        (SELECT issue_id,
                                MIN(changed_on) AS closed,
                                MAX(changed_on) AS closedlast
                        FROM changes
                        WHERE new_value IN (new_value='Fix Released' or new_value='Invalid' or new_value='Expired' or new_value='Won''t Fix')
                        GROUP BY issue_id) ch
                   WHERE issues.id = ch.issue_id
                   ORDER BY submitted_on"
  )

setClass(Class="ITSTicketsTimes",
         contains="data.frame",
         )
## Initialize by running the query that gets times for each ticket,
## and by initializing the data frames with specialized data
## (time to fix first, time to fix last, time to fix in hours, etc.)
setMethod(f="initialize",
          signature="ITSTicketsTimes",
          definition=function(.Object){
            cat("~~~ ITSTicketsTimes: initializator ~~~ \n")
            print (conf)
            q <- new ("Query", sql = query.closed[FindoutRepoKind()])
            as(.Object,"data.frame") <- run (q)
            .Object$open <- strptime(.Object$open,
                                     format="%Y-%m-%d %H:%M:%S")
            .Object$closed <- strptime(.Object$closed,
                                       format="%Y-%m-%d %H:%M:%S")
            .Object$closedlast <- strptime(.Object$closedlast,
                                           format="%Y-%m-%d %H:%M:%S")
            .Object$tofix <- round (as.numeric(
                                      difftime(.Object$closed,
                                               .Object$open,
                                               units="secs")
                                      ))
            .Object$tofixlast <- round(as.numeric(
                                         difftime(.Object$closedlast,
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
  signature="ITSTicketsTimes",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(tickets=as.data.frame(.Object))))
    sink()
  }
  )


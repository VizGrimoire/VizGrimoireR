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
## ITSTicketsMovements class
##
## Class for handling the movements of tickets (changes, comments)
##

query.movements.generic = "
      SELECT ch.issue_id AS issue_id,
        changes,
        comments 
      FROM
        (SELECT issue_id,
           COUNT(*) AS changes 
         FROM changes 
         GROUP BY issue_id) ch, 
        (SELECT issue_id,
           COUNT(*) as comments 
         FROM comments 
         GROUP BY issue_id) com 
      WHERE ch.issue_id = com.issue_id 
      ORDER BY comments DESC"

query.movements = c (
  "bugzilla" = query.movements.generic,
  "jira" = query.movements.generic,
  "launchpad" = query.movements.generic
  )

setClass(Class="ITSTicketsMovements",
         contains="data.frame",
         )
## Initialize by running the query that gets number of changes and
## comments for each ticket, and using that info for producing a
## data frame
setMethod(f="initialize",
          signature="ITSTicketsMovements",
          definition=function(.Object){
            cat("~~~ ITSTicketsMovements: initializator ~~~ \n")
            q <- new ("Query", sql = query.movements[FindoutRepoKind()])
            as(.Object,"data.frame") <- run (q)
            return(.Object)
          }
          )

##
## Create a JSON file out of a ITSTicketsMovements object
##
## Parameters:
##  - filename: name of the JSON file to write
##
library(rjson)
#setGeneric (
#  name= "JSON",
#  def=function(.Object,...){standardGeneric("JSON")}
#  )
setMethod(
  f="JSON",
  signature="ITSTicketsMovements",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(tickets=as.data.frame(.Object))))
    sink()
  }
  )

##
## Plot distribution of changes and comments
##  - filename: prefix of all files to be written with charts
##
## Plots several charts:
##  - Histogram and density of probability for changes per ticket
##  - Histogram and density of probability for comments per ticket
##
#setGeneric (
#  name= "PlotDist",
#  def=function(object,...){standardGeneric("PlotDist")}
#  )
setMethod(
  "PlotDist", "ITSTicketsMovements",
  function(object, filename) {
    data <- object$changes
    label <- "Changes"
    filename.changes <- paste (c (filename, '-changes'), collapse='')
    ## All tickets
    plotHistogramTime (data, filename.changes, label)
    plotBoxPlot (data, paste (c (filename.changes, '-boxplot'), collapse=''))

    data <- object$comments
    label <- "Comments"
    filename.comments <- paste (c (filename, '-comments'), collapse='')
    ## All tickets
    plotHistogramTime (data, filename.comments, label)
    plotBoxPlot (data, paste (c (filename.comments, '-boxplot'), collapse=''))
  }
  )


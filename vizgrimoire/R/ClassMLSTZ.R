## Copyright (C) 2013 Bitergia
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
## MLSTZ class
##
## Class for dealing with timezone (TZ) information in messages
##

setClass(Class="MLSTZ",
         contains = "data.frame"
         )

##
## Initialize with the dataframe
##
setMethod(f="initialize",
          signature="MLSTZ",
          definition=function(.Object, counts=new("TZCounts")){
              cat("~~~ MLSTZ: initializator ~~~ \n")
              as(.Object, "data.frame") <- as.data.frame(counts)
              total.messages <- sum (.Object$messages)
              total.posters <- sum (.Object$posters)
              .Object$messages.fraction <- .Object$messages / total.messages
              .Object$posters.fraction <- .Object$posters / total.posters
              .Object$messages.poster <- .Object$messages / .Object$posters
              return(.Object)
          }
          )

##
## Plot some charts for timezones
##
## file.prefix: prefix for filenames in which charts are written
##
setMethod(f="PlotCharts",
          signature="MLSTZ",
          definition=function(.Object, file.prefix=""){
              chart <- qplot (.Object$timezone,
                              .Object$messages,
                              geom="bar", stat="identity")
              qplotpdf (chart,
                        paste (c(file.prefix, "tz-messages"), collapse=''))
              chart <- qplot (.Object$timezone,
                              .Object$posters,
                              geom="bar", stat="identity")
              qplotpdf (chart,
                        paste (c(file.prefix, "tz-posters"), collapse=''))
              chart <- qplot (.Object$timezone,
                              .Object$messages.poster,
                              geom="bar", stat="identity")
              qplotpdf (chart,
                        paste (c(file.prefix, "tz-messages-poster"),
                               collapse=''))
          }
          )


##
## Obtain a dataframe with messages, posters for (rough) geographical areas
## The dataframe has region, messages, posters columns
##
setMethod(f="RegionTZ",
          signature="MLSTZ",
          definition=function(.Object){
              ## North and South America
              timezones.americas <- subset (.Object, timezone %in% -2:-9)
              ## Europe, Africa, European Russia, Middle East
              timezones.euroafrica <- subset (.Object, timezone %in% -1:5)
              ## India, East Asia, Australia
              timezones.asia <- subset (.Object, timezone %in% 6:11)
              regions <- new ("Regions", data.frame (
                  region = c("Americas", "Euroafrica", "Asia"),
                  messages = c (sum (timezones.americas$messages),
                      sum (timezones.euroafrica$messages),
                      sum (timezones.asia$messages)),
                  posters = c (sum (timezones.americas$posters),
                      sum (timezones.euroafrica$posters),
                      sum (timezones.asia$posters))
                  ))
              return (regions)
          }
          )


##
## Create a JSON file out of a MLSTZ object
##
## Parameters:
##  - filename: name of the JSON file to write
##
setMethod(
    f="JSON",
    signature="MLSTZ",
    definition=function(.Object, filename) {
        sink(filename)
        cat(toJSON(list(mlstimezones=as.data.frame(.Object))))
        sink()
    }
    )

setMethod (
    f="show",
    signature="MLSTZ",
    definition=function(object) {
        print(object)
    }
    )

##
## Create a CSV file out of a MLSTZ object
##
## Parameters:
##  - filename: name of the CSV file to write
##
setMethod(
    f="CSV",
    signature="MLSTZ",
    definition=function(.Object, filename) {
        write.csv(.Object, file = filename)
    }
    )


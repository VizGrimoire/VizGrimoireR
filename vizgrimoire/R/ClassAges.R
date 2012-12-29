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
## Ages class
##
## Class for handling ages of persons (for a certain point in time)
##
## Components of the class:
##  - date: point in time (as string, eg "2011-01-31"
##  - persons (dataframe):
##    . id: unique id for the person
##    . name: name of the person
##    . email: email of the person
##    . age: age (in days) of that person at the point in time
##

setClass(Class="Ages",
         representation = representation (date = "character",
           persons = "data.frame")
         )

## Initialize by running the query that gets dates for population,
## and by initializing the data frames with specialized data
##
setMethod(f="initialize",
          signature="Ages",
          definition=function(.Object, date = "",
                              id = NULL,
                              name = NULL,
                              email = NULL,
                              age =  NULL) {
            cat("~~~ Ages: initializator ~~~ \n")
            .Object@date <- date
            .Object@persons <- data.frame(id = id, name = name,
                                          email=email,
                                          age = age,
                                          stringsAsFactors=FALSE)
            return(.Object)
          }
          )

##
## Generic GetDataFrame function
##
setGeneric (
  name= "GetDataFrame",
  def=function(.Object,...){standardGeneric("GetDataFrame")}
  )
##
## Get dataframe with ids and ages
##
setMethod(
  f="GetDataFrame",
  signature="Ages",
  definition=function(.Object) {
    df <- .Object@persons[c("id", "name", "age")]
    df$date <- .Object@date
    return (df)
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
  signature="Ages",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(list(date = .Object@date,
                    persons = as.data.frame(.Object@persons))))
    sink()
  }
  )

##
## Generic Pyramid function
##
setGeneric (
  name= "Pyramid",
  def=function(.Object,...){standardGeneric("Pyramid")}
  )
##
## Plot pyramid of persons for a certain date
##
## The pyramid is built based on how long have they have stayed
## in the project the developers active at that date
##
## - filename: file to write pyramid to
## - periods: periods per year (1: year, 4: quarters, 12: months)
##
setMethod(
  f="Pyramid",
  signature="Ages",
  definition=function(.Object, filename = NULL, periods = 4,
    fill="red") {
    # Next is to capture "periods" in .e, needed for the ggplot call below
    .e <- environment()
    chart <- ggplot(.Object@persons, aes(x=floor(age/(365/periods))),
                    environment = .e) +
      geom_histogram(binwidth=1, colour="black", fill=fill) +
      xlab("Age") +
      ylab("Number of developers") +
      coord_flip()
    produce.charts (chart = chart, filename = filename,
                    height = 5, width = 4)
  }
  )

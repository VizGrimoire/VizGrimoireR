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
            .Object$firstdate <- strptime(.Object$firstdate,
                                          format="%Y-%m-%d %H:%M:%S")
            .Object$lastdate <- strptime(.Object$lastdate,
                                         format="%Y-%m-%d %H:%M:%S")
            .Object$stay <- round (as.numeric(
                                     difftime(.Object$lastdate,
                                              .Object$firstdate,
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

##
## Generic Pyramid function
##
setGeneric (
  name= "Pyramid",
  def=function(.Object,...){standardGeneric("Pyramid")}
  )
##
## Pyramid of developers for a certain date
##
## The pyramid is built based on how long have they have stayed
## in the project the developers active at that date
##
## - date: date as string (eg: "2010-01-01")
## - filename: file to write pyramid to
##
setMethod(
  f="Pyramid",
  signature="Demographics",
  definition=function(.Object, date, filename) {

    pdffilename <- paste (c(filename, ".pdf"), collapse='')
    active <- subset (as.data.frame (.Object),
                      firstdate <= strptime(date, format="%Y-%m-%d") &
                      lastdate >= strptime(date, format="%Y-%m-%d"))
    active$age <- round (as.numeric (difftime (
                                       strptime(date, format="%Y-%m-%d"),
                                       active$firstdate, units="days")))
    pdf(file=pdffilename, height=5, width=5)
    print (ggplot(active, aes(x=floor(age/365))) +
           geom_histogram(binwidth=1, colour="black", fill="white") +
           xlab("Age (years)") +
           ylab("Number of developers") +
           coord_flip())
    dev.off()
  }
  )

## Copyright (C) 2012, 2013 Bitergia
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
## EventsMonthly class
##
## Class for handling monthly events of any kind
##   (for example, number of closed tickets per month)
##

setClass(Class="EventsMonthly",
         contains="data.frame",
         )

##
## Initialize, by getting a dataframe.
##
## The dataframe must have the following columns:
##  - "id", which must be, for each month, year*12+month, as integer
##  - any number of columns, each with numerical values for each id
##     (values could be NA)
##
## Initialization fills in missing months, and adds some columns:
##  - year (as integer, XXXX)
##  - month (as integer, 1-12)
##  - date (as text, eg: "Feb 2012")
##
setMethod(f="initialize",
          signature="EventsMonthly",
          definition=function(.Object, data){
            cat("~~~ EventsMonthly: initializator ~~~ \n")
            ## Complete months not present
            as(.Object,"data.frame") <- completeZeroMonthly (data)
            .Object$year <- (.Object$id - 1) %/% 12
            .Object$month <- ((.Object$id - 1) %% 12) + 1
            .Object$date <- toTextDate(.Object$year, .Object$month)
            return(.Object)
          }
          )


setMethod(
  f="JSON",
  signature="EventsMonthly",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(.Object))
    sink()
  }
  )

##
## Plot a monthly chart with data in the object
##

setMethod(
  f="Plot",
  signature="EventsMonthly",
  definition=function(.Object, columns, filename, labels=columns) {
    pdffilename <- paste (c(filename, ".pdf"), collapse='')
    pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
    pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')
  
    ## Build label for Y axis
    label <- ""
    if (length(labels) == 1) {
      label = labels[1]
    } else {
      for (col in 1:length(columns)) {
        if (col != 1) {
          label <- paste (c(label, " / "), collapse='')
        }
        label = paste (c(label, labels[col], " (", colors[col] ,")"),
          collapse='')
      }
    }
  
    ## Regular plot
    pdf(file=pdffilename, height=3.5, width=5)
    timeserie <- ts (.Object[columns[1]],
                     start=c(.Object$year[1],.Object$month[1]), frequency=12)
    ts.plot (timeserie, col=colors[1], ylab=label)
    if (length (columns) > 1) {
      for (col in 2:length(columns)) {
        timeserie <- ts (.Object[columns[col]],
                         start=c(.Object$year[1],.Object$month[1]),
                         frequency=12)
        lines (timeserie, col=colors[col])
      }
    }
    dev.off()

    ## Cummulative plot
    pdf(file=pdffilenamecum, height=3.5, width=5)
    timeserie <- ts (cumsum(.Object[columns[1]]),
                     start=c(.Object$year[1],.Object$month[1]), frequency=12)
    ts.plot (timeserie, col=colors[1], ylab=label)
    if (length (columns) > 1) {
      for (col in 2:length(columns)) {
        timeserie <- ts (cumsum(.Object[columns[col]]),
                         start=c(.Object$year[1],.Object$month[1]),
                         frequency=12)
        lines (timeserie, col=colors[col])
      }
    }
    dev.off()
  }
  )

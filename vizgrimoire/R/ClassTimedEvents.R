# Copyright (C) 2012 Bitergia
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
## TimedEvents class
##
## Class for handling events with a timestamp and a parameter
##

setClass(Class="TimedEvents",
         contains="data.frame",
         )

## Initialize by selecting a row from ITSTicketsTimes
##
##  - timestamps: vector to be used as timestamps
##  - parameters: vector to be used as parameters
## Both vectors should have the same length
##  (each pair "timestamp, parameter" corresponds to an event)
##
setMethod(f="initialize",
          signature="TimedEvents",
          definition=function(.Object,timestamps,parameters){
            cat("~~~ TimedEvents: initializator ~~~ \n")
            df <- data.frame(timestamps, parameters)
            as(.Object,"data.frame") <- df[with(df, order(timestamps)),]
            ##as(.Object,"data.frame") <- data.frame(timestamps, parameters)
            ##as(.Object,"data.frame")[with(.Object, order(timestamps)), ]
            return(.Object)
          }
          )

##
## Obtain a TimeSeriesYears with yearly quantiles data 
##
## Parameters:
##  - qspec: List with quantiles to consider. Eg: c(.99,.95)
##  - firstYear: First year to consider
##  - lastYear: Last year to consider
## Returns:
##  TimeSeriesYears object
##
setGeneric (
  name= "QuantilizeYears",
  def=function(object,...){standardGeneric("QuantilizeYears")}
  )
setMethod(
  "QuantilizeYears", "TimedEvents",
  function(object, qspec,
           firstYear = GetYear(object$timestamps[1]),
           lastYear = GetYear(object$timestamps[nrow(object)])) {
    ## Prepare the quantiles matrix, with data for the quantiles of
    ## each year in rows, and data for each quantile in columns
    ## It will be a matrix of quantiles columns, and years rows
    ## Column names will be quantiles (as strings), row names will be
    ## years (as strings)
    years <- firstYear:lastYear
    quantiles <- matrix(nrow=length(years),ncol=length(qspec))
    colnames (quantiles) <- qspec
    rownames (quantiles) <- years
    eventyears <-  
    ## Now, fill in the quantiles matrix with data
    for (year in firstYear:lastYear) {
      year.events <- object[year == GetYear(object$timestamps),]
      quantiles[as.character(year),] <- quantile(year.events$parameters,
                                                 qspec, names = FALSE)
    }
    ## Now, build a data frame out of the matrix, with
    ## one column per quantile, plus one 'year' column, and one row per year
    quantilesdf <- as.data.frame(quantiles)
    # quantilesdf <- as.data.frame(quantiles,row.names=FALSE)
    quantilesdf$year <- years
    ## Creat a TimeSeriesYears object, and return it
    return (new ("TimeSeriesYears",quantilesdf,qspec))
  }
  )

##
## Obtain a TimeSeriesYears with monthly quantiles data 
##
## Parameters:
##  - qspec: List with quantiles to consider. Eg: c(.99,.95)
##  - firstYear: First year to consider
##  - firstMonth: First month to consider (0:11)
##  - lastYear: Last year to consider
##  - lastMonth: Last month to consider (0:11)
## Returns:
##  TimeSeriesMonths object
##
setGeneric (
  name= "QuantilizeMonths",
  def=function(object,...){standardGeneric("QuantilizeMonths")}
  )
setMethod(
  "QuantilizeMonths", "TimedEvents",
  function(object, qspec,
           firstYear = GetYear(object$timestamps[1]),
           firstMonth = GetMonth(object$timestamps[1]),
           lastYear = GetYear(object$timestamps[nrow(object)]),
           lastMonth = GetMonth(object$timestamps[nrow(object)])) {
    ## periods.x will be in the format year*12 + month
    periods.first <- firstYear*12 + firstMonth
    periods.last <- lastYear*12 + lastMonth
    ## Prepare the quantiles matrix, with data for the quantiles of
    ## each month in rows, and data for each quantile in columns
    ## It will be a matrix of quantiles columns, and month rows
    ## Column names will be quantiles (as strings), row names will be
    ## months (as year*12+month)
    periods <- periods.first:periods.last
    quantiles <- matrix(nrow=length(periods),ncol=length(qspec))
    colnames (quantiles) <- qspec
    rownames (quantiles) <- periods
    ## Now, fill in the quantiles matrix with data
    for (period in periods) {
      period.events <- object[period == (GetYear(object$timestamps)*12 +
                                         GetMonth(object$timestamps)),
                              ]
      quantiles[as.character(period),] <- quantile(period.events$parameters,
                                                   qspec, names = FALSE)
    }
    ## Now, build a data frame out of the matrix, with
    ## one column per quantile, plus one 'year' column, and one row per year
    quantilesdf <- as.data.frame(quantiles,row.names=FALSE)
    quantilesdf$period <- periods
    ## Creat a TimeSeriesMonths object, and return it
    return (new ("TimeSeriesMonths",quantilesdf,qspec))
  }
  )

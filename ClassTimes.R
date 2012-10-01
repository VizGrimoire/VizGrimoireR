##
## Times class
##
## Class for handling a vector with times for certain events
##  (for example, time to fix for a list of tickets)
##  - Times (elements of the vector) are difftime objects
##  - label: label to use in plots for parameter

setClass(Class="Times",
         contains="vector",
         representation=representation(
           label="character"
           )
         )

setMethod(f="initialize",
          signature="Times",
          definition=function(.Object, times, label="Time"){
            cat("~~~ Times: initializator ~~~ \n")
            as(.Object,"vector") <- times
            .Object@label <- label
            return(.Object)
          }
          )

##
## Plot distribution of times
##  - filename: prefix of all files to be written with charts
##  - unit: unit for times (mins, hours, weeks, months)
##
## Plots several charts:
##  - Histogram and density of probability for times for all tickets
##  - Histogram and density of probability for times for quickly
##      closed tickets
##  - Histogram and density of probability for times for slowly
##      closed tickets
## Quick and slow tickets are split at quantil .5
##
setGeneric (
  name= "PlotDist",
  def=function(object,...){standardGeneric("PlotDist")}
  )
setMethod(
  "PlotDist", "Times",
  function(object, filename, unit="days") {
    # Prepare factor to convert seconds to units
    if (unit == "mins") {
      factor <- 60
    } else if (unit == "hours") {
      factor <- 60*60
    } else if (unit == "days") {
      factor <- 60*60*24
    } else if (unit == "weeks") {
      factor <- 60*60*24*7
    }
    data <- (as(object,"vector") %/% factor)
    label <- paste (c(object@label, ' (', unit, ')'), collapse='')
    ## All tickets
    plotHistogramTime (data, filename, label)
    plotBoxPlot (data, paste (c (filename, '-boxplot'), collapse=''))
    ## Quickly closed tickets
    threshold <- quantile(data, .5)
    quickly <- data[data <= threshold]
    if (length(quickly) > 0) {
      plotHistogramTime (quickly, paste (c (filename, '-quick'), collapse=''),
                         label)
      plotBoxPlot (quickly, paste (c (filename, '-quick-boxplot'), collapse=''))
    }
    ## Slowly closed tickets
    slowly <- data[data > threshold]
    if (length(slowly) > 0) {
      plotHistogramTime (slowly, paste (c (filename, '-slow'), collapse=''),
                         label)
      plotBoxPlot (slowly, paste (c (filename, '-slow-boxplot'), collapse=''))
    }
  }
  )


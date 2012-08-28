##
## Times class
##
## Class for handling a vector with times for certain events
##  (for example, time to fix for a list of tickets)
##

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
##
## Plots several charts:
##  - Histogram and density of probability for all tickets
##  - Histogram and density of probability for quickly closed tickets
##  - Histogram and density of probability for slowly closed tickets
## Threshold is for splitting in quick/slow (in days)
##
setGeneric (
  name= "PlotDist",
  def=function(object,...){standardGeneric("PlotDist")}
  )
setMethod(
  "PlotDist", "Times",
  function(object, filename, unit = 'days', threshold = 30) {
    data <- as(object,"vector")
    label <- paste (c(object@label, ' (', unit, ')'), collapse='')
    ## All tickets
    plotHistogramTime (data, filename, label)
    plotBoxPlot (data, paste (c (filename, '-boxplot'), collapse=''))
    ## Quickly closed tickets
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

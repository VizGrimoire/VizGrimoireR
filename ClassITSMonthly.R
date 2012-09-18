##
## ITSMonthly class
##
## Class for handling monthly data related to ITS
##   (for example, number of closed tickets per month)
##

setClass(Class="ITSMonthly",
         contains="data.frame",
         )

setGeneric (
  name= "Query",
  def=function(.Object,...){standardGeneric("Query")}
  )

##
## Void Query method, resturns an empty string.
## Only descendants of this class, with proper Query functions
## should be instantiated, not this one
##
setMethod(
  f="Query",
  signature="ITSMonthly",
  definition=function(.Object) {
    return ("")
  }
  )

##
## Initialize, by running the query for the object
##  and returning the corresponding data frame.
##
## Rows produced by the query should include one called "id",
##  which must be, for each month, year*12+month, as integer
##
## Initialization fills in missing months, and adds some columns:
##  - year (as integer, XXXX)
##  - month (as integer, 1-12)
##  - date (as text, eg: "Feb 2012")
##
setMethod(f="initialize",
          signature="ITSMonthly",
          definition=function(.Object){
            cat("~~~ ITSMonthly: initializator ~~~ \n")
            ## Query() should dispatch to the child
            q <- new ("QueryTimeSerie", sql = Query(.Object))
            ## Complete months not present
            as(.Object,"data.frame") <- completeZeroMonthly (run (q))
            .Object$year <- (.Object$id - 1) %/% 12
            .Object$month <- ((.Object$id - 1) %% 12) + 1
            .Object$date <- toTextDate(.Object$year, .Object$month)
            return(.Object)
          }
          )

setMethod(
  f="JSON",
  signature="ITSMonthly",
  definition=function(.Object, filename) {
    sink(filename)
    cat(toJSON(.Object))
    sink()
  }
  )

##
## Plot a monthly chart with data in the object
##

## setGeneric (
##   name= "Plot",
##   def=function(.Object,...){standardGeneric("Plot")}
##   )

setMethod(
  f="Plot",
  signature="ITSMonthly",
  definition=function(.Object, columns, filename, labels=columns) {
    pdffilename <- paste (c(filename, ".pdf"), collapse='')
    pdffilenamediff <- paste (c(filename, "-diff.pdf"), collapse='')
    pdffilenamecum <- paste (c(filename, "-cumsum.pdf"), collapse='')
  
    ## Build label for Y axis
    label <- ""
    for (col in 1:length(columns)) {
      if (col != 1) {
        label <- paste (c(label, " / "), collapse='')
      }
      label = paste (c(label, labels[col], " (", colors[col] ,")"),
        collapse='')
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

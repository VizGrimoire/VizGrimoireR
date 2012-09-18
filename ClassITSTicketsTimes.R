##
## ITSTicketsTimes class
##
## Class for handling the many times of each ticket
##  (open, closed, changed, etc.)
##

query <- "SELECT issue_id, issue,
     	submitted_on AS time_open,
        YEAR (submitted_on) AS year_open,
        time_closed,
	time_closed_last,
	TIMESTAMPDIFF (DAY, submitted_on, ch.time_closed) AS ttofix,
        TIMESTAMPDIFF (DAY, submitted_on, ch.time_closed_last) AS ttofixlast,
	TIMESTAMPDIFF (HOUR, submitted_on, ch.time_closed) AS ttofixh,
        TIMESTAMPDIFF (HOUR, submitted_on, ch.time_closed_last) AS ttofixlasth,
	TIMESTAMPDIFF (MINUTE, submitted_on, ch.time_closed) AS ttofixm,
        TIMESTAMPDIFF (MINUTE, submitted_on, ch.time_closed_last) AS ttofixlastm
      FROM issues, (
         SELECT
           issue_id,
           MIN(changed_on) AS time_closed,
           MAX(changed_on) AS time_closed_last
         FROM changes
         WHERE (new_value='RESOLVED' OR new_value='CLOSED')
         GROUP BY issue_id) ch
      WHERE issues.id = ch.issue_id
      ORDER BY submitted_on"

setClass(Class="ITSTicketsTimes",
         contains="data.frame",
         representation=representation(
           tofix = "Times",
           tofix.last = "Times",
           tofix.hours = "Times",
           tofix.minutes = "Times"
           )
         )
## Initialize by running the query that gets times for each ticket,
## and by initializing the data frames with specialized data
## (time to fix first, time to fix last, time to fix in hours, etc.)
setMethod(f="initialize",
          signature="ITSTicketsTimes",
          definition=function(.Object){
            cat("~~~ ITSTicketsTimes: initializator ~~~ \n")
            q <- new ("QueryTimeSerie", sql = query)
            as(.Object,"data.frame") <- run (q)
            tofix <- new ("Times", .Object$ttofix,
                          "Time to fix, first close")
            tofix.last <- new ("Times", .Object$ttofixlast,
                               "Time to fix, last close")
            tofix.hours <- new ("Times", .Object$ttofixh,
                                "Time to fix, first close")
            tofix.minutes <- new ("Times", .Object$ttofixm,
                                  "Time to fix, first close")
            return(.Object)
          }
          )

##
## Create a JSON file out of a ITSTicketsTimes object
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
  signature="ITSTicketsTimes",
  definition=function(.Object, filename) {
    ## df <- data.frame(years=years, data.frame (as.ts(.Object)))
    ## data <- list (data = df, labels = .Object@labels)
    sink(filename)
    cat(toJSON(list(tickets=as.data.frame(.Object),
                    tofix=.Object@tofix,
                    tofix.last=.Object@tofix.last,
                    tofix.hours=.Object@tofix.hours,
                    tofix.minutes=.Object@tofix.minutes)))
                    
    sink()
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
  "QuantilizeYears", "ITSTicketsTimes",
  function(object, qspec, firstYear = object$year_open[1],
           lastYear = object$year_open[nrow(object)]) {
    ## Prepare the quantiles matrix, with data for the quantiles of
    ## each year in rows, and data for each quantile in columns
    ## It will be a matrix of quantiles columns, and years rows
    ## Column names will be quantiles (as strings), row names will be
    ## years (as strings)
    years <- firstYear:lastYear
    quantiles <- matrix(nrow=length(years),ncol=length(qspec))
    colnames (quantiles) <- qspec
    rownames (quantiles) <- years
    ## Now, fill in the quantiles matrix with data
    for (year in firstYear:lastYear) {
      yearData <- object[object$year_open == year,]
      time_to_fix_minutes <- yearData$ttofixm
      quantiles[as.character(year),] <- quantile(time_to_fix_minutes,
                                                 qspec, names = FALSE)
    }
    ## Now, build a data frame out of the matrix, with
    ## one column per quantile, plus one 'year' column, and one row per year
    quantilesdf <- as.data.frame(quantiles,row.names=FALSE)
    quantilesdf$year <- years
    ## Creat a TimeSeriesYears object, and return it
    return (new ("TimeSeriesYears",quantilesdf,qspec))
  }
  )

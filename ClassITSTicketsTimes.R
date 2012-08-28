#
# ITSTicketsTimes class
#
# Class for handling the many times of each ticket
#  (open, closed, changed, etc.)
#

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
           tofix = "data.frame",
           tofix.last = "data.frame",
           tofix.hours = "data.frame",
           tofix.minutes = "data.frame"
           )
         )
# Initialize by running the query that gets times for each ticket,
# and by initializing the data frames with specialized data
# (time to fix first, time to fix last, time to fix in hours, etc.)
setMethod(f="initialize",
          signature="ITSTicketsTimes",
          definition=function(.Object){
            cat("~~~ ITSTicketsTimes: initializator ~~~ \n")
            q <- new ("QueryTimeSerie", sql = query)
            as(.Object,"data.frame") <- run (q)
            tofix <- .Object$ttofix
            tofix.last <- .Object$ttofix
            tofix.hours <- .Object$ttofixh
            tofix.minutes <- .Object$ttofixm
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
  name= "PlotTimeDist",
  def=function(object,...){standardGeneric("PlotTimeDist")}
  )
setMethod(
  "PlotTimeDist", "ITSTicketsTimes",
  function(object, filename, unit = 'days', threshold = 30,
                          variable = 'Time') {
    data <- as(object,"data.frame")
    label <- paste (c(variable, ' (', unit, ')'), collapse='')
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

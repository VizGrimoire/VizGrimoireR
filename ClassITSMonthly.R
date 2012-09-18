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
          signature="ITSMonthlyOpen",
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

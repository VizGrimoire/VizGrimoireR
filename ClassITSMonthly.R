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

setMethod(f="initialize",
          signature="ITSMonthlyOpen",
          definition=function(.Object){
            cat("~~~ ITSMonthlyOpen: initializator ~~~ \n")
            # New tickets per week
            q <- new ("QueryTimeSerie", sql = Query(.Object))
            as(.Object,"data.frame") <- run (q)
            print (.Object)
          }
          )

##
## ITSMonthlyVarious class
##
## Class for handling various parameters related with tickets, per month
##
## This is the class that is usually instantiated to get a full monthly
##  dataset with information about the evolution of activities related to
##  tickets.

setClass(Class="ITSMonthlyVarious",
         contains="ITSMonthly",
         )

##
## Initialization is by merging objects of all the sister classes
##
## Therefore, this class is a way of getting a data frame with all
##  the relevant monthly parameters
##
setMethod(f="initialize",
          signature="ITSMonthlyVarious",
          definition=function(.Object){
            cat("~~~ ITSMonthlyVarious: initializator ~~~ \n")
            as(.Object,"data.frame") <- new ("ITSMonthlyOpen")
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyChanged"))
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyClosed"))
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyLastClosed"))
            ## Complete months not present
            ## This is important, because although previous objects don't
            ## have holes, they could start / end at different months
            as(.Object,"data.frame") <- completeZeroMonthly (.Object)
            return(.Object)
          }
          )

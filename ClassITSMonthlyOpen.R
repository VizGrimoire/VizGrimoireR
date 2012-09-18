##
## ITSMonthlyOpen class
##
## Class for handling open tickets per month
##

setClass(Class="ITSMonthlyOpen",
         contains="ITSMonthly",
         )

##
## Initialize by running the query that gets tickets open per month
##
setMethod(f="initialize",
          signature="ITSMonthlyOpen",
          definition=function(.Object){
            cat("~~~ ITSMonthlyOpen: initializator ~~~ \n")
            # New tickets per week
            query <- "
             SELECT YEAR (submitted_on) * 52 + WEEK (submitted_on) AS yearweek,
               DATE_FORMAT(submitted_on, '%Y %V') AS year_week,
	       YEAR (submitted_on) AS year,
               WEEK (submitted_on) AS week,
               COUNT(*) AS open
             FROM issues
             GROUP BY yearweek"
            q <- new ("QueryTimeSerie", sql = query)
            as(.Object,"data.frame") <- run (q)
            print (.Object)
          }
          )

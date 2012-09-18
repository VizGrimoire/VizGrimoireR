##
## ITSMonthlyOpen class
##
## Class for handling open tickets per month
##

setClass(Class="ITSMonthlyOpen",
         contains="ITSMonthly",
         )

##
## Query method, resturns SQL string to get tickets open per month.
##
setMethod(
  f="Query",
  signature="ITSMonthlyOpen",
  definition=function(.Object) {
    query <- "
      SELECT year(submitted_on) * 12 + month(submitted_on) AS id,
        year(submitted_on) AS year,
        month(submitted_on) AS month,
        DATE_FORMAT (submitted_on, '%b %Y') as date,
        count(submitted_by) AS open,
        count(distinct(submitted_by)) AS openers
      FROM issues
      GROUP BY year,month
      ORDER BY year,month"
    return (query)
  }
  )

##
## Initialize by running the query that gets tickets open per month
##
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

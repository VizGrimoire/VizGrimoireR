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
        count(submitted_by) AS open,
        count(distinct(submitted_by)) AS openers
      FROM issues
      GROUP BY year(submitted_on) * 12 + month(submitted_on)
      ORDER BY year(submitted_on) * 12 + month(submitted_on)"
    return (query)
  }
  )

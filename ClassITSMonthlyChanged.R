##
## ITSMonthlyChanged class
##
## Class for handling changed tickets per month
##

setClass(Class="ITSMonthlyChanged",
         contains="ITSMonthly",
         )

##
## Query method, resturns SQL string to get tickets changed per month.
##
setMethod(
  f="Query",
  signature="ITSMonthlyChanged",
  definition=function(.Object) {
    query <- "
      SELECT year(changed_on) * 12 + month(changed_on) AS id,
        count(changed_by) AS changed,
        count(distinct(changed_by)) AS changers
      FROM changes
      GROUP BY year(changed_on) * 12 + month(changed_on)
      ORDER BY year(changed_on) * 12 + month(changed_on)"
    return (query)
  }
  )

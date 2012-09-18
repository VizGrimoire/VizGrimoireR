##
## ITSMonthlyClosed class
##
## Class for handling closed tickets per month
##

setClass(Class="ITSMonthlyClosed",
         contains="ITSMonthly",
         )

##
## Query method, resturns SQL string to get tickets closed per month.
##
setMethod(
  f="Query",
  signature="ITSMonthlyClosed",
  definition=function(.Object) {
    query <- "
      SELECT year(time_closed) * 12 + month(time_closed) AS id,
        count(*) AS closed
      FROM (
        SELECT issue_id, MIN(changed_on) time_closed
        FROM changes 
        WHERE new_value='RESOLVED' OR new_value='CLOSED' 
        GROUP BY issue_id) closes
      GROUP BY year(time_closed) * 12 + month(time_closed)
      ORDER BY year(time_closed) * 12 + month(time_closed)"
    return (query)
  }
  )

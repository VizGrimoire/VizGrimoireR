##
## ITSMonthlyLastClosed class
##
## Class for handling closed tickets (last close) per month
##

setClass(Class="ITSMonthlyLastClosed",
         contains="ITSMonthly",
         )

##
## Query method, resturns SQL string to get tickets closed per month
##  (last close)
##
setMethod(
  f="Query",
  signature="ITSMonthlyLastClosed",
  definition=function(.Object) {
    query <- "
      SELECT year(time_closed) * 12 + month(time_closed) AS id,
        count(*) AS lastclosed
      FROM (
        SELECT issue_id, MAX(changed_on) time_closed
        FROM changes 
        WHERE new_value='RESOLVED' OR new_value='CLOSED' 
        GROUP BY issue_id) closes
      GROUP BY year(time_closed) * 12 + month(time_closed)
      ORDER BY year(time_closed) * 12 + month(time_closed)"
    return (query)
  }
  )

## Copyright (C) 2012 Bitergia
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## This file is a part of the vizGrimoire.R package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
##
## ITSMonthlyClosed class
##
## Class for handling closed tickets (first close) per month
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

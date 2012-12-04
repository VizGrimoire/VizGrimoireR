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
## This file is a part of the vizgrimoire R package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
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

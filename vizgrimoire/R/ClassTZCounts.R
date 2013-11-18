## Copyright (C) 2013 Bitergia
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
## TZCounts class
##
## Root for a class for getting a dataframe with raw information
##  about counts for timezones (TZ)
##

setClass(Class="TZCounts",
         contains = "data.frame"
         )

##
## Syntetize an SQL query for getting timezones, given a limit
##  such as "YEAR(first_date) = 2012".
## Returns such a query
## (Auxiliary function)
##
## Rationale for the calculus of timezones in the query below:
##  We want to have hours from -12 to +11, as offsets from GMT
##  We start with times in seconds, as positive or negative, which is what
##  MLStats seems to collect. For example, +3600 is GMT+1.
##  We have times well above +11 (such as +13 for New Zeland in some messages)
##  and below -12 too.
## Now, the formulae:
##  First of all, we calculate seconds modulus 3600 to work in hours
##  Add 36, to move eg -12..+11 to 24..47, and convert to modulo 24
##    to move to 00..23
##  (adding 12, to move -12..+11 to 0..23 is not enough, since it would
##    convert -13 to -1, because -1 mod 24 is -1.
##    Assumption: there are no times bwlow -24)
##
QueryMLSTZCount <- function (limits = "TRUE") {
    return (paste (c("SELECT
  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone, 
  COUNT(first_date_tz) AS messages,
  COUNT(DISTINCT(messages_people.email_address)) as posters
FROM messages, messages_people
WHERE ", limits, " AND
  messages.message_ID = messages_people.message_id AND
  messages_people.type_of_recipient = \"From\"
GROUP BY timezone"),  collapse=''))
}

##
## Initialize by running a query that gets counts per timezone
##  Returns: dataframe with:
##   $timezone: interger, -12:11
##   counts per timezone
## Default: QueryTZCount (messages and posters for MLS)
##
setMethod(f="initialize",
          signature="TZCounts",
          definition=function(.Object, query=QueryMLSTZCount()){
              cat("~~~ TZCounts: initializator ~~~ \n")
              q <- new ("Query", sql = query)
              as(.Object, "data.frame") <- run (q)
              return(.Object)
          }
          )

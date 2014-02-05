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
## TZCountsDST class
##
## Class for getting a dataframe with raw information
##  about counts for timezones (TZ), considering DST (daylight saving time)
##  The algorithm for considering DST is very rough, but usually gives a
##  better approximation than not considering it
##

setClass(Class="TZCountsDST",
         contains = "TZCounts"
         )

##
## Get a timeframe with timezone counts (roughly) considering DST
##
## Rationale: for summer (May-Oct) substract one hour before estimating
##  time zone.
##  For example, +2GMT in Summer, for CEST, is really +1GMT timezone.
## We query twice in SQL (Summer and Winter) and then add the corresponding
##  data frames.
## This sort of works for North America and Europe. This doesn't work
##  for East Asia, most of South America, Africa, since they don't seem to
##  use DST, or use Southern DST, during the Southern Summer.
## Winter, summer are according to Northern Hemisphere
##
query.tz.count.summer <- "SELECT
  ((first_date_tz div 3600) + 35) mod 24 - 12 AS timezone, 
  COUNT(first_date_tz) AS smessages,
  COUNT(DISTINCT(messages_people.email_address)) as sposters
FROM messages, messages_people
WHERE %s AND
  (month(first_date) >= 4 OR month(first_date) <= 10) AND
  messages.message_ID = messages_people.message_id AND
  messages_people.type_of_recipient = \"From\"
GROUP BY timezone"

query.tz.count.winter <- "SELECT
  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone, 
  COUNT(first_date_tz) AS wmessages,
  COUNT(DISTINCT(messages_people.email_address)) as wposters
FROM messages, messages_people
WHERE %s AND
  (month(first_date) < 4 OR month(first_date) > 10) AND
  messages.message_ID = messages_people.message_id AND
  messages_people.type_of_recipient = \"From\"
GROUP BY timezone"

QueryMLSTZCountDST <- function (limits = "TRUE") {
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
          signature="TZCountsDST",
          definition=function(.Object, limits = "TRUE"){
              cat("~~~ TZCountsDST: initializator ~~~ \n")
              query <- sprintf(query.tz.count.summer, limits)
              timezones.summer <- run (new ("Query", sql = query))
              query <- sprintf(query.tz.count.winter, limits)
              timezones.winter <- run (new ("Query", sql = query))
              timezones <- merge(timezones.winter,
                                 timezones.summer,
                                 all=TRUE)
              timezones [is.na(timezones)] <- 0
              timezones$messages <- timezones$smessages + timezones$wmessages
              timezones$posters <- timezones$sposters + timezones$wposters
              as(.Object, "data.frame") <- timezones
              return(.Object)
          }
          )

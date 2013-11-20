#! /usr/bin/Rscript --vanilla

## Copyright (C) 2012, 2013 Bitergia
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
## http://vizgrimoire.bitergia.org/
##
## Analyze and extract metrics data gathered by MLStats tool
## http://metricsgrimoire.github.io/MailingListStats/
##
## This script analyzes data from a single mailing list
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
## Usage:
## singlelist.R -d dbname -u user -p passwd
##
## Example:
##  LANG=en_US R_LIBS=rlib:$R_LIBS singlelist.R -d proydb \
##  -u jgb -p XXX

library("vizgrimoire")
library("lubridate")
library("ggplot2")
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 


conf <- ConfFromOptParse()
SetDBChannel (database = conf$database,
	      user = conf$dbuser, password = conf$dbpassword)

##
## TZs with a row per month and year
##
## query.tz.count <- "SELECT
##  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone, 
##  COUNT(first_date_tz) AS messages,
##  COUNT(DISTINCT(messages_people.email_address)) as posters,
##  MONTH(messages.first_date) as month,
##  YEAR(messages.first_date) as year
## FROM messages, messages_people
## WHERE messages.message_ID = messages_people.message_id AND
##   messages_people.type_of_recipient = \"From\"
## GROUP BY timezone, year, month"

## Timezones for all messages

timezones <- new ("MLSTZ")
PlotCharts (timezones, "/tmp/")
regions <- RegionTZ (timezones)
PlotShares (regions, "/tmp/")

## Timezones for messages in 2012
tzcounts.2012 <- new ("TZCounts", QueryMLSTZCount("YEAR(first_date) = 2012"))
timezones.2012 <- new ("MLSTZ", tzcounts.2012)
PlotCharts (timezones.2012, "/tmp/2012-")
regions.2012 <- RegionTZ (timezones.2012)
PlotShares (regions.2012, "/tmp/2012-")

##
## Improved calculus, roughly considering DST
##
tzcounts.dst <- new ("TZCountsDST")
timezones.dst <- new ("MLSTZ", tzcounts.dst)
regions.dst <- RegionTZ (timezones.dst)
PlotShares (regions.dst, "/tmp/dst-")


##
## Returns the first and last dates in MLS repository
##
## Returns a vector with two strings: firstdate and lastdate
##
MLSDatesPeriod <- function () {
  q <- new ("Query",
            sql = "SELECT DATE(MIN(first_date)) as startdate,
                     DATE(MAX(first_date)) as enddate FROM messages")
  dates <- run(q)
  return (dates[1,])
}

##
## Get charts for generations for each year, since the last one in the
## database backwards.
##
demos <- new ("Demographics", type="mls", months=6)
period <- MLSDatesPeriod()
cut.date <- ymd(period["enddate"])
first.date <- ymd(period["startdate"]) + years(1)
while (cut.date >= first.date) {
  cut.date <- cut.date - years(1)
  print (as.character(cut.date))
  ProcessAges (demos, as.character(cut.date), "/tmp/pyramid-")
}

query.tz.count <- "SELECT
  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone, 
  count(first_date_tz) AS messages
FROM messages
GROUP BY ((first_date_tz div 3600) + 36) mod 24 - 12"


##
## Number of messages per person per quarter, written in a CSV file
##
sql <- "SELECT COUNT(messages.message_ID) AS messages,
  messages_people.email_address AS poster,
  YEAR (messages.first_date) AS year,
QUARTER(messages.first_date) AS quarter
FROM messages, messages_people
WHERE messages.message_ID = messages_people.message_id AND
  messages_people.type_of_recipient = \"From\"
GROUP BY year, quarter, poster"

q <- new ("Query", sql=sql)
messages <- run (q)
## Period column will be "yyyy-q"
messages <- within (messages, period <- paste(year, quarter, sep="-"))
## Apply "sum" by year, quarter to number of messages
by.quarter <- data.frame(periods = unique(messages$period))
by.quarter$messages <- tapply(messages$messages,
                             INDEX=list(messages$period),
                             FUN=sum)
by.quarter$posters <- tapply(messages$messages,
                             INDEX=list(messages$period),
                             FUN=length)
by.quarter$median <- tapply(messages$messages,
                            INDEX=list(messages$period),
                            FUN=median)
by.quarter$mean <- tapply(messages$messages,
                            INDEX=list(messages$period),
                            FUN=mean)

write.csv(by.quarter, file = "/tmp/by_quarter.csv")
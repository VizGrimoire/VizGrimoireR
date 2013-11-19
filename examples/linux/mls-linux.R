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
## Analyze and extract metrics data gathered by MailingListsStats tool
## http://metricsgrimoire.github.io/MailingListStats/
##
## This script analyzes data from the Linux Kernel mailing lists git repository
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
## Usage:
## mls-linux.R -d dbname -u user -p passwd -i uids_dbname \
##   [-r repositories,companies] --granularity days|weeks|months|years] \
##   --destination destdir
##
## Example:
##  LANG=en_US R_LIBS=rlib:$R_LIBS mls-linux.R -d proydb \
##  -u jgb -p XXX -i uiddb -r repositories,companies --granularity weeks \
##  --destination destdir

library("vizgrimoire")
library("lubridate")
library("ggplot2")
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database,
	      user = conf$dbuser, password = conf$dbpassword)

##
## Plot messages sent per timezone
##
## Expects a dataframe with a column for timezones (as -12..11 GMT) and
##   another one with number of messages for that timezone
##
plot.tz <- function (df, file="", height = 4, width = 6,
                     xlab = "Timezones (relative to GMT)") {
  chart <- qplot (df$timezone, df$messages, geom="bar", stat="identity") +
    xlab(xlab) +
    ylab("Messages")
  produce.charts (chart = chart, filename = file,
                  height = height, width = width)  
}

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
query.tz.count <- "SELECT
  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone, 
  count(first_date_tz) AS messages
FROM messages
GROUP BY ((first_date_tz div 3600) + 36) mod 24 - 12"

q <- new ("Query", sql = query.tz.count)
timezones <- run (q)
timezones.total <- sum (timezones$messages)
timezones$fraction <- timezones$messages / timezones.total
chart <- qplot (timezones$timezone, timezones$messages, geom="bar", stat="identity") +
  xlab("Timezones (relative to GMT)") +
  ylab("Messages")
produce.charts (chart = chart, filename = "/tmp/linux-mls-timezones",
                height = 4, width = 6)

query.tz.year.count <- "SELECT
  ((first_date_tz div 3600) + 36) mod 24 - 12 AS timezone,
  YEAR(first_date) as year,
  count(first_date_tz) AS messages
FROM messages
GROUP BY timezone, year
ORDER BY year, timezone"
q <- new ("Query", sql = query.tz.year.count)
timezones.year <- run (q)
timezones.2002 <- subset (timezones.year, year=="2002")
plot.tz (timezones.2002, "/tmp/linux-mls-timezones-2002",
         height = 2, width = 10, xlab="")
timezones.2007 <- subset (timezones.year, year=="2007")
plot.tz (timezones.2007, "/tmp/linux-mls-timezones-2007",
         height = 2, width = 10, xlab="")
timezones.2012 <- subset (timezones.year, year=="2012")
plot.tz (timezones.2012, "/tmp/linux-mls-timezones-2012",
         height = 2, width = 10, xlab="")

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




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
## Usage:
##  R --no-restore --no-save --args dbschema user passwd < scm-demographics.R

## Note: this script works with cvsanaly databases obtained from git

library("vizgrimoire")

## Analyze command line args, and produce config params from them
conf <- ConfFromParameters("kdevelop", "jgb", "XXX")
SetDBChannel (conf$user, conf$password, conf$database)

sql <- "SELECT 
    author_id as id, people.name as name, people.email as email,
    count(scmlog.id) as commits,
    MIN(scmlog.date) as firstdate, MAX(scmlog.date) as lastdate
FROM
    scmlog, people
WHERE
    scmlog.author_id = people.id
GROUP by author_id"

q <- new ("Query", sql = sql)

periods <- run (q)

periods$firstdate <- strptime(periods$firstdate,
                              format="%Y-%m-%d %H:%M:%S")
periods$lastdate <- strptime(periods$lastdate,
                              format="%Y-%m-%d %H:%M:%S")
hist(periods$firstdate, "quarters", freq=TRUE)
hist(periods$lastdate, "quarters", freq=TRUE)
periods$stay <- round (as.numeric(
  difftime(periods$lastdate, periods$firstdate, units="days")))
hist(periods$stay)
active2010 <- subset (periods,
  firstdate <= strptime("2010-01-01", format="%Y-%m-%d") &
  lastdate >= strptime("2010-01-01", format="%Y-%m-%d"))
active2010$age <- round (as.numeric (difftime (
  strptime("2010-01-01", format="%Y-%m-%d"),
  active2010$firstdate, units="days")))
active2010$age.years <- floor(active2010$age/365)
hist(active2010$age)

library("ggplot2")
ggplot(active2010, aes(x=age)) +
  geom_histogram(binwidth=365, colour="black", fill="white") +
  coord_flip()

ggplot(active2010, aes(x=floor(age/365))) +
  geom_histogram(binwidth=1, colour="black", fill="white") +
  coord_flip()


demos <- new ("Demographics")
JSON (demos, "demos.json")


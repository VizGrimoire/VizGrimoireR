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
## This file is part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## its.R
##
##
## Authors:
##   Luis Cañas-Díaz <lcanas@bitergia.com>


# ITS tests

test.CountBacklogTickets <- function()
    {
        start = as.POSIXlt("2006-09-11")
        end = as.POSIXlt("2008-12-01")
        
        open_status = 'Open'
        reopened_status = 'Reopened'
        statuses = c(open_status, reopened_status)

        res <- read.table("data/issues_log001.data", colClasses = c(date = "POSIXct"))
        samples.week <- GetWeeksBetween(start, end, extra=TRUE)
        samples.month <- GetMonthsBetween(start, end, extra=TRUE)

        # real tests start here
        weekly.pending <- CountBacklogTickets(samples.week,res, statuses)
        colnames(weekly.pending) <- c('week', 'backlog.tickets')
        number.rows <- nrow(weekly.pending)
        expect_that(117, equals(number.rows))
        unique.weeks <- length(unique(weekly.pending$week))
        expect_that(117, equals(unique.weeks))
        total.tickets <- sum(weekly.pending$backlog.tickets)
        expect_that(1288, equals(total.tickets))

        monthly.pending <- CountBacklogTickets(samples.month,res, statuses)
        colnames(monthly.pending) <- c('month', 'backlog.tickets')
        number.rows <- nrow(monthly.pending)
        expect_that(28, equals(number.rows))
        unique.weeks <- length(unique(monthly.pending$month))
        expect_that(28, equals(unique.weeks))
        total.tickets <- sum(monthly.pending$backlog.tickets)
        expect_that(566, equals(total.tickets))
}

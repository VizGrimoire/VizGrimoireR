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
## auxiliary.R
##
##
## Authors:
##   Luis Cañas-Díaz <lcanas@bitergia.com>


#Auxiliary tests

test.completeZeroPeriods <- function()
    {
        init_date <- "2010-01-01"
        end_date <- "2014-01-01"
        raw_months <- read.table("data/months001.data")
        filled_months <- completeZeroPeriodIds(raw_months, "months", init_date, end_date)
        res1 <- length(unique(filled_months$date))
        expect_that(49, equals(res1))
        res2 <- sum(filled_months$commits)
        expect_that(423, equals(res2))

        raw_weeks <- read.table("data/weeks001.data")
        filled_weeks <- completeZeroPeriodIds(raw_weeks, "weeks", init_date, end_date)
        res3 <- nrow(filled_weeks)
        expect_that(210, equals(res3))
        res4 <- length(unique(filled_weeks$unixtime))
        expect_that(210, equals(res4))
        res5 <- length(unique(filled_weeks$date))
        expect_that(49, equals(res5))
        res6 <- sum(filled_weeks$commits)
        expect_that(423, equals(res6))
}

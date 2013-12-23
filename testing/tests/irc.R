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
## This file is a part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## irc.R
##
##
## Authors:
##   Luis Cañas-Díaz <lcanas@bitergia.com>




test.StaticNumSentIRC.Month <- function()
{
    result <- StaticNumSentIRC('month', "'2013-01-01'", "'2013-02-01'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(9325, equals(number))

    result <- StaticNumSentIRC('month', "'2012-01-01'", "'2012-02-01'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(0, equals(number))    
}

test.StaticNumSentIRC.Week <- function()
{
    result <- StaticNumSentIRC('week', "'2013-01-01'", "'2013-01-08'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(2177, equals(number))

    result <- StaticNumSentIRC('month', "'2012-01-01'", "'2012-01-08'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(0, equals(number))
}

test.StaticNumSendersIRC.Month <- function()
{
    result <- StaticNumSendersIRC('month', "'2013-01-01'", "'2013-02-01'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(28, equals(number))

    result <- StaticNumSendersIRC('month', "'2012-01-01'", "'2012-02-01'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(0, equals(number))
}

test.StaticNumSendersIRC.Week <- function()
{
    result <- StaticNumSendersIRC('week', "'2013-01-01'", "'2013-01-08'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(14, equals(number))

    result <- StaticNumSendersIRC('week', "'2012-01-01'", "'2012-01-08'", NA, list(NA, NA))
    number <- as.numeric(result[1])
    expect_that(0, equals(number))
}

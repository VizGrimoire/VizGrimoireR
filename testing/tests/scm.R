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
## scm.R
##
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>




test.prints <- function()
{
    expect_that(print(" , repositories r "), prints_text(GetSQLRepositoriesFrom()))

}

test.commits <- function()
{
    expect_that(54, equals(nrow(EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}


test.StaticNumCommits <- function()
{
    expect_that(18710, equals(as.numeric(StaticNumCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))[1])))
}

test.StaticNumAuthors <- function()
{
    expect_that(538, equals(as.numeric(StaticNumAuthors('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}


test.StaticNumCommitters <- function()
{
    expect_that(523, equals(as.numeric(StaticNumCommitters('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticNumFiles <- function()
{
    expect_that(13426, equals(as.numeric(StaticNumFiles('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumBranches <- function()
{
    expect_that(4, equals(as.numeric(StaticNumBranches('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumRepositories <- function()
{
    expect_that(34, equals(as.numeric(StaticNumRepositories('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumActions <- function()
{
    expect_that(54421, equals(as.numeric(StaticNumActions('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgCommitsPeriod <- function()
{
    expect_that(359.8077, equals(as.numeric(StaticAvgCommitsPeriod('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgFilesPeriod <- function()
{
    expect_that(258.1923, equals(as.numeric(StaticAvgFilesPeriod('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgCommitsAuthor <- function()
{
    expect_that(34.777, equals(as.numeric(StaticAvgCommitsAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgAuthorPeriod <- function()
{
    expect_that(10.3462, equals(as.numeric(StaticAvgAuthorPeriod('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgCommitterPeriod <- function()
{
    expect_that(10.0577, equals(as.numeric(StaticAvgCommitterPeriod('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgFilesAuthor <- function()
{
    expect_that(25.6711, equals(as.numeric(StaticAvgFilesAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}


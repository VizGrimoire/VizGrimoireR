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

#Evolutionary functions
test.EvolCommits <- function()
{
    expect_that(54, equals(nrow(EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolAuthors <- function()
{
    expect_that(54, equals(nrow(EvolAuthors('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolCommitters <- function()
{
    expect_that(54, equals(nrow(EvolCommitters('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}


test.EvolFiles <- function()
{
    expect_that(54, equals(nrow(EvolFiles('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolLines <- function()
{
    expect_that(54, equals(nrow(EvolLines('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolBranches <- function()
{
    expect_that(54, equals(nrow(EvolBranches('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolRepositories <- function()
{
    expect_that(54, equals(nrow(EvolRepositories('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolActions <- function()
{
    expect_that(54, equals(nrow(EvolActions('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolAvgCommitsAuthor <- function()
{
    expect_that(54, equals(nrow(EvolAvgCommitsAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolAvgFilesAuthor <- function()
{
    expect_that(54, equals(nrow(EvolAvgFilesAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}



#Aggregated functions
test.StaticNumCommits <- function()
{
    # 20786 before removing merge commits
    expect_that(13725, equals(as.numeric(StaticNumCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))[1])))
}

test.StaticNumAuthors <- function()
{
    expect_that(564, equals(as.numeric(StaticNumAuthors('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}


test.StaticNumCommitters <- function()
{
    expect_that(536, equals(as.numeric(StaticNumCommitters('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticNumFiles <- function()
{
    expect_that(14518, equals(as.numeric(StaticNumFiles('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumBranches <- function()
{
    expect_that(5, equals(as.numeric(StaticNumBranches('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumRepositories <- function()
{
    expect_that(45, equals(as.numeric(StaticNumRepositories('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticNumActions <- function()
{
    expect_that(59781, equals(as.numeric(StaticNumActions('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgCommitsPeriod <- function()
{
    # 399.7308 before removing merge commits
    expect_that(263.9423, equals(as.numeric(StaticAvgCommitsPeriod('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgFilesPeriod <- function()
{
    expect_that(279.1923, equals(as.numeric(StaticAvgFilesPeriod('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.StaticAvgCommitsAuthor <- function()
{
    # 36.8546 before removing merge commits
    expect_that(24.3351, equals(as.numeric(StaticAvgCommitsAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgAuthorPeriod <- function()
{
    expect_that(10.8462, equals(as.numeric(StaticAvgAuthorPeriod('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgCommitterPeriod <- function()
{
    expect_that(10.3077, equals(as.numeric(StaticAvgCommitterPeriod('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.StaticAvgFilesAuthor <- function()
{
    expect_that(25.7411, equals(as.numeric(StaticAvgFilesAuthor('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}


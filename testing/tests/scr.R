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
## scr.R
##
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>


#Evolutionary info tests

test.EvolReviewsSubmitted <- function()
{
    expect_that(54, equals(nrow(EvolReviewsSubmitted('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsOpened <- function()
{
    expect_that(4, equals(nrow(EvolReviewsOpened('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsNew <- function()
{
    expect_that(2, equals(nrow(EvolReviewsNew('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsNewChanges <- function()
{
    expect_that(0, equals(nrow(EvolReviewsNewChanges('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsInProgress <- function()
{
    expect_that(0, equals(nrow(EvolReviewsInProgress('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsClosed <- function()
{
    expect_that(54, equals(nrow(EvolReviewsClosed('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsMerged <- function()
{
    expect_that(54, equals(nrow(EvolReviewsMerged('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsMergedChanges <- function()
{
    expect_that(0, equals(nrow(EvolReviewsMergedChanges('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsAbandoned <- function()
{
    expect_that(53, equals(nrow(EvolReviewsAbandoned('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolReviewsAbandonedChanges <- function()
{
    expect_that(0, equals(nrow(EvolReviewsAbandonedChanges('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolPatchesApproved <- function()
{
    expect_that(54, equals(nrow(EvolPatchesApproved('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolPatchesVerified <- function()
{
    expect_that(54, equals(nrow(EvolPatchesVerified('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolPatchesCodeReview <- function()
{
    expect_that(54, equals(nrow(EvolPatchesCodeReview('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolPatchesSent <- function()
{
    expect_that(53, equals(nrow(EvolPatchesSent('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA)))))
}

test.EvolWaiting4Reviewer <- function()
{
    expect_that(2, equals(nrow(EvolWaiting4Reviewer('week', "'2012-01-01'", "'2013-01-01'", idb, list(NA, NA)))))
}

test.EvolWaiting4Submitter <- function()
{
    expect_that(1, equals(nrow(EvolWaiting4Submitter('week', "'2012-01-01'", "'2013-01-01'", idb,  list(NA, NA)))))
}

test.EvolReviewers <- function()
{
    expect_that(54, equals(nrow(EvolReviewers('week', "'2012-01-01'", "'2013-01-01'", idb,  list(NA, NA)))))
}




#Aggregated info tests


test.StaticReviewsSubmitted <- function()
{
    expect_that(16067, equals(as.numeric(StaticReviewsSubmitted('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsOpened <- function()
{
    expect_that(5, equals(as.numeric(StaticReviewsOpened('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsNew <- function()
{
    expect_that(2, equals(as.numeric(StaticReviewsNew('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsInProgress <- function()
{
    expect_that(0, equals(as.numeric(StaticReviewsInProgress('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsClosed <- function()
{
    expect_that(16062, equals(as.numeric(StaticReviewsClosed('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsMerged <- function()
{
    expect_that(13628, equals(as.numeric(StaticReviewsMerged('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticReviewsAbandoned <- function()
{
    expect_that(2434, equals(as.numeric(StaticReviewsAbandoned('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticPatchesApproved <- function()
{
    expect_that(13328, equals(as.numeric(StaticPatchesApproved('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticPatchesVerified <- function()
{
    expect_that(28218, equals(as.numeric(StaticPatchesVerified('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticPatchesCodeReview <- function()
{
    expect_that(35883, equals(as.numeric(StaticPatchesCodeReview('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticPatchesSent <- function()
{
    expect_that(11941, equals(as.numeric(StaticPatchesSent('week', "'2012-01-01'", "'2013-01-01'", list(NA, NA))[1])))
}

test.StaticWaiting4Reviewer <- function()
{
    expect_that(2, equals(as.numeric(StaticWaiting4Reviewer('week', "'2012-01-01'", "'2013-01-01'", idb, list(NA, NA))[1])))
}

test.StaticWaiting4Submitter <- function()
{
    expect_that(1, equals(as.numeric(StaticWaiting4Submitter('week', "'2012-01-01'", "'2013-01-01'", idb,  list(NA, NA))[1])))
}

test.StaticReviewers <- function()
{
    expect_that(1545, equals(as.numeric(StaticReviewers('week', "'2012-01-01'", "'2013-01-01'", idb,  list(NA, NA))[1])))
}





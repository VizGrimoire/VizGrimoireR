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
## its.R
##
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>


test.IssuesOpened.Agg.Week <- function(){
    expect_that(7809, equals(as.numeric(AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Agg.Week.Repository <- function(){
    expect_that(2416, equals(as.numeric(AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'")))))
}

test.IssuesOpened.Agg.Week.Company <- function(){
    expect_that(151, equals(as.numeric(AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'")))))
}


test.IssuesOpened.Agg.Month <- function(){
    expect_that(7809, equals(as.numeric(AggIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Agg.Month.Company <- function(){
    expect_that(151, equals(as.numeric(AggIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'")))))
}

test.IssuesOpened.Evol.Week <- function(){
    print(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))))
    expect_that(54, equals(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Evol.Week.Company <- function(){
    print(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"))))
    expect_that(44, equals(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'")))))
}


test.IssuesOpened.Evol.Month <- function(){
    print(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))))
    expect_that(12, equals(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Evol.Month.Company <- function(){
    print(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'"))))
    expect_that(12, equals(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'")))))
}


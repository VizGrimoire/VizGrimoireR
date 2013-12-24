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



#Opened issues

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
    expect_that(54, equals(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Evol.Week.Company <- function(){
    expect_that(44, equals(nrow(EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'")))))
}


test.IssuesOpened.Evol.Month <- function(){
    expect_that(12, equals(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpened.Evol.Month.Company <- function(){
    expect_that(12, equals(nrow(EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'")))))
}


#People opening issues

test.IssuesOpeners.Agg.Week <- function(){
    expect_that(941, equals(as.numeric(AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpeners.Agg.Week.Repository <- function(){
    expect_that(523, equals(as.numeric(AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'")))))
}

test.IssuesOpeners.Agg.Week.Company <- function(){
    expect_that(14, equals(as.numeric(AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'")))))
}


test.IssuesOpeners.Agg.Month <- function(){
    expect_that(941, equals(as.numeric(AggIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpeners.Agg.Month.Company <- function(){
    expect_that(14, equals(as.numeric(AggIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'")))))
}

test.IssuesOpeners.Evol.Week <- function(){
    expect_that(54, equals(nrow(EvolIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpeners.Evol.Week.Company <- function(){
    expect_that(44, equals(nrow(EvolIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'")))))
}


test.IssuesOpeners.Evol.Month <- function(){
    expect_that(12, equals(nrow(EvolIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.IssuesOpeners.Evol.Month.Company <- function(){
    expect_that(12, equals(nrow(EvolIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', "'Red Hat'")))))
}

#Closed issues

test.IssuesClosed.Agg.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4716, equals(as.numeric(AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosed.Agg.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(1653, equals(as.numeric(AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosed.Agg.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(5, equals(as.numeric(AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosedAgg.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4716, equals(as.numeric(AggIssuesClosed('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}


test.IssuesClosed.Evol.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(52, equals(nrow(EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosed.Evol.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(52, equals(nrow(EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosed.Evol.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4, equals(nrow(EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosedEvol.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(12, equals(nrow(EvolIssuesClosed('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}


#People closing issues
test.IssuesClosers.Agg.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosers.Agg.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(77, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosers.Agg.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosersAgg.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosers.Agg.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosers.Agg.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(77, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosers.Agg.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosersAgg.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}
test.IssuesClosers.Agg.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosers.Agg.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(77, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosers.Agg.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4, equals(as.numeric(AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosersAgg.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(172, equals(as.numeric(AggIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}


test.IssuesClosers.Evol.Week <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(52, equals(nrow(EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}

test.IssuesClosers.Evol.Week.Repository <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(52, equals(nrow(EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("repository", "'https://bugs.launchpad.net/nova'"), closed_condition))))
}

test.IssuesClosers.Evol.Week.Company <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(4, equals(nrow(EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list("company", "'Red Hat'"), closed_condition))))
}

test.IssuesClosersEvol.Month <- function(){
    closed_condition = " (new_value='Fix Committed') "
    expect_that(12, equals(nrow(EvolIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA), closed_condition))))
}


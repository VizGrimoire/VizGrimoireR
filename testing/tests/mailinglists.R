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
## mailinglists.R
##
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>




#Evolutionary functions
test.EvolEmailsSent.Week <- function()
{
    print(nrow(EvolEmailsSent('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))))
    expect_that(50, equals(nrow(EvolEmailsSent('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolEmailsSent.Month <- function()
{
    print(nrow(EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))))
    expect_that(12, equals(nrow(EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))))
}

test.EvolEmailsSent.Company <- function()
{
    print(nrow(EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Red Hat'))))
    expect_that(12, equals(nrow(EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Red Hat')))))
}


test.EvolMLSSenders.Week <- function()
{
    print(nrow(EvolMLSSenders('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA))))
    expect_that(50, equals(nrow(EvolMLSSenders('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolMLSSenders.Month <- function()
{
    print(nrow(EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA))))
    expect_that(12, equals(nrow(EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolMLSSenders.Company <- function()
{
    print(nrow(EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Rackspace'))))
    expect_that(12, equals(nrow(EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Rackspace')))))
}


test.EvolMLSSendersResponse.Week <- function()
{
    print(nrow(EvolMLSSendersResponse('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA))))
    expect_that(50, equals(nrow(EvolMLSSendersResponse('week', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolMLSSendersResponse.Month <- function()
{
    print(nrow(EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA))))
    expect_that(12, equals(nrow(EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list(NA, NA)))))
}

test.EvolMLSSendersResponse.Company <- function()
{
    print(nrow(EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Rackspace'))))
    expect_that(12, equals(nrow(EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", conf$identities_db, list('company', 'Rackspace')))))
}


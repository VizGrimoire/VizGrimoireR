#!/usr/bin/Rscript

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
## run_test.R
##
## Tests for SCM data analysis
##
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>


library('RUnit')
library('testthat')
library('vizgrimoire')
library('zoo')

#R --vanilla --args -d fake -u root  -i jenkins_scm_vizr_1783 < init_tests.R

options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 
conf <- ConfFromOptParse()
idb = conf$identities_db
error = FALSE

SetDBChannel (database = "jenkins_mls_vizr_1783", user = conf$dbuser, password = conf$dbpassword)
idb = conf$identities_db
test.suite <- defineTestSuite("MailingLists",
                              dirs = file.path("tests"),
                              testFileRegexp = 'mls.R$')
test.result <- runTestSuite(test.suite)
if (getErrors(test.result)[1]>0) {q(status=1)}

printTextProtocol(test.result)

SetDBChannel (database = "jenkins_scm_vizr_1783", user = conf$dbuser, password = conf$dbpassword)
idb = conf$identities_db
test.suite <- defineTestSuite("SCM",
                              dirs = file.path("tests"),
                              testFileRegexp = 'scm.R$')
test.result <- runTestSuite(test.suite)
if (getErrors(test.result)[1]>0) {q(status=1)}

printTextProtocol(test.result)


SetDBChannel (database = "jenkins_scr_vizr_1783", user = conf$dbuser, password = conf$dbpassword)
test.suite <- defineTestSuite("SCR",
                              dirs = file.path("tests"),
                              testFileRegexp = 'scr.R$')
test.result <- runTestSuite(test.suite)
if (getErrors(test.result)[1]>0){q(status=1)}

printTextProtocol(test.result)


SetDBChannel (database = "jenkins_scm_vizr_1783", user = conf$dbuser, password = conf$dbpassword)
idb = conf$identities_db

test.suite <- defineTestSuite("StatTest",
                              dirs = file.path("tests"),
                              testFileRegexp = 'StatTest.R$')

test.result <- runTestSuite(test.suite)
if (getErrors(test.result)[1]>0){q(status=1)}

SetDBChannel (database = "jenkins_irc_vizr_1783", user = conf$dbuser, password = conf$dbpassword)
test.suite <- defineTestSuite("IRC",
                              dirs = file.path("tests"),
                              testFileRegexp = 'irc.R$')
test.result <- runTestSuite(test.suite)
if (getErrors(test.result)[1]>0){q(status=1)}


printTextProtocol(test.result)




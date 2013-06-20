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


#R --vanilla --args -d fake -u root  -i lcanas_cvsanaly_openstack_1376 < init_tests.R

options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

conf <- ConfFromOptParse()
SetDBChannel (database = "lcanas_cvsanaly_openstack_1376", user = conf$dbuser, password = conf$dbpassword)
idb = conf$identities_db

test.suite <- defineTestSuite("SCM",
                              dirs = file.path("tests"),
                              testFileRegexp = 'scm.R')



test.result <- runTestSuite(test.suite)

printTextProtocol(test.result)



SetDBChannel (database = "acs_gerrit_launchpad_1411", user = conf$dbuser, password = conf$dbpassword)

test.suite <- defineTestSuite("SCR",
                              dirs = file.path("tests"),
                              testFileRegexp = 'scr.R')



test.result <- runTestSuite(test.suite)

printTextProtocol(test.result)



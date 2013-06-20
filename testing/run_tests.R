library('RUnit')
library('testthat')
library('vizgrimoire')


# R --vanilla < run_tests.R
#R --vanilla --args -d lcanas_cvsanaly_openstack_1376 -u root  < run_tests.R

options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)

print(EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA)))

test.suite <- defineTestSuite("example",
                              dirs = file.path("tests"),
                              testFileRegexp = '^\\d+\\.R')

test.result <- runTestSuite(test.suite)

printTextProtocol(test.result)


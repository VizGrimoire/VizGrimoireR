library('RUnit')
library('testthat')

source('SCM.R')

# R --vanilla < run_tests.R

test.suite <- defineTestSuite("example",
                              dirs = file.path("tests"),
                              testFileRegexp = '^\\d+\\.R')

test.result <- runTestSuite(test.suite)

printTextProtocol(test.result)


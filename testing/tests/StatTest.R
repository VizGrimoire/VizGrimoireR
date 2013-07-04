

test.BBollinger <- function()
{
Evol<-EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))
tBBollinger<-BBollinger(Evol$commits,4,0.95)
expect_that(51, equals(nrow(BBollinger(Evol$commits,4,0.95))))
expect_that(rep(TRUE,nrow(BBollinger(Evol$commits,4,0.95))), equals(tBBollinger$bbsup>tBBollinger$bbinf))
}

test.RollMean<-function()
{
Evol<-EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))
tRollMean<-RollMean(Evol$commits,4,8)
expect_that(54, equals(nrow(RollMean(Evol$commits,4,8))))
expect_that(rep(0,3), equals(tRollMean$mms[1:3]))
expect_that(rep(0,7), equals(tRollMean$mml[1:7]))
}

test.DiffRoll<-function()
{
Evol<-EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))
tDiffRoll<-DiffRoll(Evol$commits,4,8)
expect_that(47, equals(nrow(tDiffRoll)))
}
 

test.ExpoAv<-function()
{
Evol<-EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))
tExpoAv<-ExpoAv(Evol$commits,4,8)
expect_that(54, equals(nrow(ExpoAv(Evol$commits,4,8))))
expect_that(rep(0,3), equals(tExpoAv$shortA[1:3]))
expect_that(rep(0,7), equals(tExpoAv$longA[1:7]))
}


test.remove_outliers<-function()
{
Evol<-EvolCommits('week', "'2012-01-01'", "'2013-01-01'", NA, list(NA, NA))
expect_that(18517, equals(sum(na.omit((remove_outliers(Evol$commits))))))
}


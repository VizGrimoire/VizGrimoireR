#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

#WHOLE DATA
rm data/json/*
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -g weeks < scm-analysis.R
sleep 5
R --vanilla --args -d $1 -u root -i $1 -r companies -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -g weeks < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -g weeks < mls-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -g weeks < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -g weeks < its-analysis.R
rm data/whole_project/*
mv data/json/* data/whole_project/

#GRIZZLY
rm data/json/*
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2012-09-27 -g weeks < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2012-09-27 -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2012-09-27 -g weeks < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2012-09-27 -g weeks < mls-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2012-09-27 -g weeks < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2012-09-27 -g weeks < its-analysis.R
rm data/grizzly/*
mv data/json/* data/grizzly/

#FOLSOM
rm data/json/*
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2012-04-05 -e 2012-09-27 -g weeks < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2012-04-05 -e 2012-09-27 -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2012-04-05 -e 2012-09-27 -g weeks < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2012-04-05 -e 2012-09-27 -g weeks < mls-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2012-04-05 -e 2012-09-27 -g weeks < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2012-04-05 -e 2012-09-27 -g weeks < its-analysis.R
rm data/folsom/*
mv data/json/* data/folsom/

#ESSEX
rm data/json/*
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2011-11-22 -e 2012-04-05 -g weeks < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2011-11-22 -e 2012-04-05 -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2011-11-22 -e 2012-04-05 -g weeks < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2011-11-22 -e 2012-04-05 -g weeks < mls-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2011-11-22 -e 2012-04-05 -g weeks < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2011-11-22 -e 2012-04-05 -g weeks < its-analysis.R
rm data/essex/*
mv data/json/* data/essex/


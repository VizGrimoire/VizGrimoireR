#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Example: ./run_scripts.sh acs_cvsanaly_allura_1049 acs_mlstats_allura_1049 acs_bicho_allura_1049

#WHOLE DATA
rm data/json/*
mkdir -p data/whole_project
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2010-05-01 -e 2013-04-05 -g weeks < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2010-05-01 -e 2013-04-05 -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2010-05-01 -e 2013-04-05 -g weeks < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2010-05-01 -e 2013-04-05 -g weeks < mls-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2010-05-01 -e 2013-04-05 -g weeks -t allura < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2010-05-01 -e 2013-04-05 -g weeks -t allura < its-analysis.R
rm data/whole_project/*
mv data/json/* data/whole_project/

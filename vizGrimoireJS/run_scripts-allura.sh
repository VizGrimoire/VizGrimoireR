#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Allura: ./run_scripts-allura.sh acs_cvsanaly_allura_1049 acs_mlstats_allura_1049 acs_bicho_allura_1049

rm -rf data/json
mkdir -p data/json
mkdir -p data/allura

period="weeks"

#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g $period < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g $period < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g $period < mls-analysis.R
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g $period < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g $period < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g $period < scm-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g $period -t allura < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g $period -t allura < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g $period -t allura < its-analysis.R

rm data/allura/*
mv data/json/* data/allura/

#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Allura: ./run_scripts-allura.sh acs_cvsanaly_allura_1049 acs_mlstats_allura_1049 acs_bicho_allura_1049

period="months"
project="allura"
dstart="2009-10-14"
dend="2013-01-07"

rm -rf data/json
mkdir -p data/json
mkdir -p data/$project

#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s $dstart -e $dend -g $period < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s $dstart -e $dend -g $period < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r countries -s $dstart -e $dend -g $period < mls-analysis.R
#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s $dstart -e $dend -g $period < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s $dstart -e $dend -g $period < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r countries -s $dstart -e $dend -g $period < scm-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s $dstart -e $dend -g $period -t $project < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s $dstart -e $dend -g $period -t $project < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r countries -s $dstart -e $dend -g $period -t $project < its-analysis.R

rm data/$project/*
mv data/json/* data/$project/

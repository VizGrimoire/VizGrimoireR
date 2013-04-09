#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Example: ./run_scripts.sh dic_cvsanaly_openstack_1289_2013_04_04 dic_mlstats_openstack_1290_2013_04_04 lcanas_bicho_openstack_1291_2013_04_04
# Allura: ./run_scripts-allura.sh acs_cvsanaly_allura_1049 acs_mlstats_allura_1049 acs_bicho_allura_1049

rm data/json/*
mkdir -p data/allura

#SCM
R --vanilla --args -d $1 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
R --vanilla --args -d $1 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
#ITS
R --vanilla --args -d $3 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R
R --vanilla --args -d $3 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -r repositories -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r companies -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R
R --vanilla --args -d $2 -u root -i $1 -r countries -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R

rm data/allura/*
mv data/json/* data/allura/

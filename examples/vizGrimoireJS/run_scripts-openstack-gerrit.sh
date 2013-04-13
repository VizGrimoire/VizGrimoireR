#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Example: ./run_scripts-openstack-gerrit.sh dic_cvsanaly_openstack_1289_2013_04_04 dic_mlstats_openstack_1290_2013_04_04 acs_gerrit_launchpad_1411

#WHOLE DATA
rm data/json/*
mkdir -p data/whole_project
#ITS
R --vanilla --args -d $3 -u root -i $1 -s 2010-05-27 -e 2013-04-04 -g weeks < its-analysis-gerrit.R
rm data/whole_project/*
mv data/json/* data/whole_project/
exit
#SCM
R --vanilla --args -d $1 -u root -i $1 -s 2010-05-27 -e 2013-04-04 -g weeks < scm-analysis.R
#MLS
R --vanilla --args -d $2 -u root -i $1 -s 2010-05-27 -e 2013-04-04 -g weeks < mls-analysis.R
rm data/whole_project/*
mv data/json/* data/whole_project/

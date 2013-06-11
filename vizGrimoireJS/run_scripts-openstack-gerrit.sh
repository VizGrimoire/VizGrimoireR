#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Example: ./run_scripts-openstack-gerrit.sh acs_gerrit_launchpad_1411 acs_gerrit_launchpad_1411 acs_gerrit_launchpad_1411

# R --vanilla --args -d acs_gerrit_launchpad_1411 -u root -i acs_gerrit_launchpad_1411  -s 2011-07-25 -e 2013-04-05 -g weeks < scr-analysis.R

rm data/json/*
R --vanilla --args -d $3 -u root -i $1 -s 2011-07-25 -e 2013-04-05 -g weeks < scr-analysis.R

#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database
#$4 = end date
#$5 = destination
#$6 = log file (not used)
#$6 = SCR database


START=2010-05-27
END=$4
PROJECT=openstack
DIR=$5 #not used so far
#LOGS=$6 (not used)



# Example: ./run_scripts-openstack.sh dic_cvsanaly_openstack_1289_2013_04_04 dic_mlstats_openstack_1290_2013_04_04 lcanas_bicho_openstack_1291_2013_04_04

#WHOLE DATA
rm data/json/*
mkdir -p data/whole_project
#SCM
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $1 -u root -i $1 -r repositories,companies -s $START -e $END -g weeks < scm-analysis.R
#MLS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $2 -u root -i $1 -r repositories,companies -s $START -e $END -g weeks < mls-analysis.R
#ITS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $3 -u root -i $1 -r repositories,companies -s $START -e $END -g weeks -t launchpad < its-analysis.R
#SCR 
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $6 -u root -i $1  -s $START -e $END -g weeks  < scr-analysis.R
rm data/whole_project/*
mv data/json/* data/whole_project/

#HAVANA
rm data/json/*
mkdir -p data/havana
#SCM
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $1 -u root -i $1 -r repositories,companies -s 2013-04-04 -e $END -g weeks < scm-analysis.R
#MLS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $2 -u root -i $1 -r repositories,companies -s 2013-04-04 -e $END -g weeks < mls-analysis.R
#ITS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $3 -u root -i $1 -r repositories,companies -s 2013-04-04 -e $END -g weeks -t launchpad < its-analysis.R
#SCR
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $6 -u root -i $1  -s 2013-04-04 -e $END -g weeks < scr-analysis.R
rm data/havana/*
mv data/json/* data/havana/



#GRIZZLY
rm data/json/*
mkdir -p data/grizzly
#SCM
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $1 -u root -i $1 -r repositories,companies -s 2012-09-27 -e 2013-04-04 -g weeks < scm-analysis.R
#MLS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $2 -u root -i $1 -r repositories,companies -s 2012-09-27 -e 2013-04-04 -g weeks < mls-analysis.R
#ITS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $3 -u root -i $1 -r repositories,companies -s 2012-09-27 -e 2013-04-04 -g weeks -t launchpad < its-analysis.R
#SCR
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $6 -u root -i $1  -s 2012-09-27 -e 2013-04-04 -g weeks < scr-analysis.R
rm data/grizzly/*
mv data/json/* data/grizzly/

#FOLSOM
rm data/json/*
mkdir -p data/folsom
#SCM
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $1 -u root -i $1 -r repositories,companies -s 2012-04-04 -e 2012-09-27 -g weeks < scm-analysis.R
#MLS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $2 -u root -i $1 -r repositories,companies -s 2012-04-04 -e 2012-09-27 -g weeks < mls-analysis.R
#ITS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $3 -u root -i $1 -r repositories,companies -s 2012-04-04 -e 2012-09-27 -g weeks -t launchpad < its-analysis.R
#SCR
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $6 -u root -i $1  -s 2012-04-04 -e 2013-09-27 -g weeks < scr-analysis.R
rm data/folsom/*
mv data/json/* data/folsom/

#ESSEX
rm data/json/*
mkdir -p data/essex
#SCM
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $1 -u root -i $1 -r repositories,companies -s 2011-11-22 -e 2012-04-04 -g weeks < scm-analysis.R
#MLS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $2 -u root -i $1 -r repositories,companies -s 2011-11-22 -e 2012-04-04 -g weeks < mls-analysis.R
#ITS
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $3 -u root -i $1 -r repositories,companies -s 2011-11-22 -e 2012-04-04 -g weeks -t launchpad < its-analysis.R
#SCR
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -d $6 -u root -i $1  -s 2011-11-22 -e 2012-04-04 -g weeks < scr-analysis.R
rm data/essex/*
mv data/json/* data/essex/


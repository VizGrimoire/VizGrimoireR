#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database

# Liferay: ./run_scripts-liferay.sh lcanas_cvsanaly_liferay_1423 acs_mlstats_liferay_forums_1294 lcanas_bicho_liferay_1250

START=2004-08-05
END=2013-03-01
PROJECT=liferay
LOGS=liferay.log

rm data/json/*
mkdir -p data/$PROJECT

#SCM
echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
echo "In SCM Analysis ..."
R --vanilla --args -d $1 -u root -p root -i $1 -r repositories -s $START -e $END -g months < scm-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $1 -u root -p root -i $1 -r companies -s $START -e $END -g months < scm-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $1 -u root -p root -i $1 -r countries -s $START -e $END -g months < scm-analysis.R >> $LOGS 2>&1
#ITS
echo "In ITS Analysis ..."
R --vanilla --args -d $3 -u root -p root -i $1 -r repositories -s $START -e $END -g months -t allura < its-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $3 -u root -p root -i $1 -r companies -s $START -e $END -g months -t allura < its-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $3 -u root -p root -i $1 -r countries -s $START -e $END -g months -t allura < its-analysis.R >> $LOGS 2>&1
#MLS
echo "In MLS Analysis ..."
R --vanilla --args -d $2 -u root -p root -i $1 -r repositories -s $START -e $END -g months < mls-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $2 -u root -p root -i $1 -r companies -s $START -e $END -g months < mls-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $2 -u root -p root -i $1 -r countries -s $START -e $END -g months < mls-analysis.R >> $LOGS 2>&1
rm data/$PROJECT/*
mv data/json/* data/$PROJECT/

#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database
#$4 = end date
#$5 = destination

# Liferay: ./run_scripts-liferay.sh lcanas_cvsanaly_liferay_1423 acs_mlstats_liferay_forums_1294 lcanas_bicho_liferay_1250 2013-03-01 /tmp/

START=2004-08-05
#END=2013-03-01
END=$4
PROJECT=liferay
LOGS=liferay.log
DIR=$5

rm $5/data/json/*
mkdir -p $5/data/json
mkdir -p $5/data/$PROJECT
echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
#MLS
echo "In MLS Analysis ..."
R --vanilla --args -d $2 -u root -p root -i $1 -r repositories -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $2 -u root -p root -i $1 -r companies -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $2 -u root -p root -i $1 -r countries -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1
#SCM
echo "In SCM Analysis ..."
R --vanilla --args -d $1 -u root -p root -i $1 -r repositories -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $1 -u root -p root -i $1 -r companies -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $1 -u root -p root -i $1 -r countries -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1
#ITS
echo "In ITS Analysis ..."
R --vanilla --args -d $3 -u root -p root -i $1 -r repositories -s $START -e $END -o $DIR -g months -t allura < its-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $3 -u root -p root -i $1 -r companies -s $START -e $END -o $DIR -g months -t allura < its-analysis.R >> $LOGS 2>&1
R --vanilla --args -d $3 -u root -p root -i $1 -r countries -s $START -e $END -o $DIR -g months -t allura < its-analysis.R >> $LOGS 2>&1
rm $DIR/data/$PROJECT/*
mv $DIR/data/json/* $DIR/data/$PROJECT/

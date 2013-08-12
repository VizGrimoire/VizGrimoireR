#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database
#$4 = end date
#$5 = destination
#$6 = SCR database
#$7 = IRC database

START=2010-01-01
#END=2013-03-01
END=$4
LOGS=generic.log
DIR=$5
# REPORTS="repositories,countries,companies,people"
# REPORTS="repositories"
REPORTS="none"

echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
#SCM
echo "In SCM Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $1 -u root -i $1 -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1
#ITS
echo "In ITS Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t redmine < its-analysis.R >> $LOGS 2>&1

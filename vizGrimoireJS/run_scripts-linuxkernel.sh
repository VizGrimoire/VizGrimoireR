#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database
#$4 = end date
#$5 = destination
#$6 = SCR database
#$7 = IRC database
#$8 = Log file
#$9 = Bicho backend

START=1999-01-01
#END=2013-03-01
END=$4
LOGS=generic.log
DIR=$5
# REPORTS="repositories,countries,companies,people"
REPORTS="repositories"
MIN_PARAM=7

mv $LOGS $LOGS.old

if [ $# -lt $MIN_PARAM ]
then
    echo "Incorrect number of params:" $# ". Should be $MIN_PARAM min"
fi

echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
#MLS
echo "In MLS Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $2 -u root -i $1 -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1

#SCM
echo "In SCM Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $1 -u root -i $1 -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1

#!/bin/bash
#$1 = SCM database
#$2 = MLS database
#$3 = ITS database
#$4 = end date
#$5 = destination
#$6 = SCR database
#$7 = IRC database
#$8 = Bicho backend

# ./run_scripts-mediawiki.sh acs_cvsanaly_mediawiki_1571 acs_mlstats_mediawiki_1466 acs_bicho_mediawiki_1466 2013-06-01 /tmp

START=2009-10-14
#END=2013-03-01
END=$4
LOGS=generic.log
DIR=$5
# REPORTS="repositories,countries,companies,people"
REPORTS="repositories"
MIN_PARAM=7

if [ $# -lt $MIN_PARAM ]
then
    echo "Incorrect number of params:" $# ". Should be $MIN_PARAM min"
fi

BICHO="bugzilla"
if [ -n "$9" ]; then BICHO=$9; fi

echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
#MLS
echo "In MLS Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $2 -u root -i $1 -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1

#SCM
echo "In SCM Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $1 -u root -i $1 -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1

#ITS
echo "In ITS Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t $BICHO < its-analysis.R >> $LOGS 2>&1

# SCR: repositories not working yet
echo "In SCR Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r none -d $6 -u root -i $1  -s $START -e $END -o $DIR -g months  < scr-analysis.R >> $LOGS 2>&1

# IRC
echo "In IRC Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $7 -u root -i $1  -s $START -e $END -o $DIR -g months  < irc-analysis.R >> $LOGS 2>&1

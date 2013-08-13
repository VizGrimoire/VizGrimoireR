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

START=2009-10-14
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

BICHO="bugzilla"
if [ -n "${10}" ]; then BICHO=${10}; fi

# Different bicho backend name in Bicho and VizR
if [ $BICHO == "bg" ]; then BICHO="bugzilla"; fi
if [ $BICHO == "lp" ]; then BICHO="launchpad"; fi

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
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t $BICHO < its-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t $BICHO < its-analysis.R >> $LOGS 2>&1

# SCR: repositories not working yet
echo "In SCR Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r repositories-basic -d $6 -u root -i $1  -s $START -e $END -o $DIR -g months  < scr-analysis.R >> $LOGS 2>&1

# IRC
echo "In IRC Analysis ..."
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS,people -d $7 -u root -i $1  -s $START -e $END -o $DIR -g months  < irc-analysis.R >> $LOGS 2>&1

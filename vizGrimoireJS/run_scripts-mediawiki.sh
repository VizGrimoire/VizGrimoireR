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

START=2002-01-01
#END=2013-03-01
END=$4
LOGS=mediawiki.log
DIR=$5
# REPORTS="repositories,countries,companies,people"
REPORTS="repositories,people"

echo "Analisys from $START to $END"
echo "LOGS in $LOGS"
mv $LOGS $LOGS.old
#MLS
echo "In MLS Analysis ..."
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $2 -u root -i $1 -s $START -e $END -o $DIR -g months < mls-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $2 -u root -i $1 -s $START -e $END -o $DIR -g months < mls-analysis.R >> $LOGS 2>&1

#SCM
echo "In SCM Analysis ..."
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $1 -u root -i $1 -s $START -e $END -o $DIR -g months < scm-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $1 -u root -i $1 -s $START -e $END -o $DIR -g months < scm-analysis.R >> $LOGS 2>&1

#ITS
echo "In ITS Analysis ..."
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t bugzilla < its-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $3 -u root -i $1 -s $START -e $END -o $DIR -g months -t bugzilla < its-analysis.R >> $LOGS 2>&1

# SCRdb=acs_gerrit_mediawiki_1753
IRCdb=acs_irc_automatortest_1938

# SCR
echo "In SCR Analysis ..."
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r repositories,people -d $6 -u root -i $1  -s $START -e $END -o $DIR -g months  < scr-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r repositories,people -d $6 -u root -i $1  -s $START -e $END -o $DIR -g months  < scr-analysis.R >> $LOGS 2>&1

# IRC
echo "In IRC Analysis ..."
echo "LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $IRCdb -u root -i $1  -s $START -e $END -o $DIR -g months  < irc-analysis.R" >> $LOGS 2>&1
LANG= R_LIBS=../../r-lib:$R_LIBS R --vanilla --args -r $REPORTS -d $IRCdb -u root -i $1  -s $START -e $END -o $DIR -g months  < irc-analysis.R >> $LOGS 2>&1

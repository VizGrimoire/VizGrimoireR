#!/bin/bash
# Automator script to analyze Mediawiki project
# Mediawiki: ./run_scripts-mediawiki.sh

PROJECT=mediawiki
LOGS=mediawiki.log

rm -rf data/json
rm -rf data/$PROJECT
mkdir -p data/json
mkdir -p data/$PROJECT

SCMdb=acs_cvsanaly_mediawiki_1571
MLSdb=acs_mlstats_mediawiki_1466
ITSdb=acs_bicho_mediawiki_1466
START=2009-10-14
END=2013-06-01
REPORTS="repositories,countries,companies,people"

#MLS
R --vanilla --args -d $MLSdb -u root -i $SCMdb -r $REPORTS -s $STAR -e $END -g months < mls-analysis.R
#SCM
R --vanilla --args -d $SCMdb -u root -i $SCMdb -r $REPORTS -s $STAR -e $END -g months < scm-analysis.R
#ITS
R --vanilla --args -d $ITSdb -u root -i $SCMdb -r $REPORTS -s $STAR -e $END -g months -t allura < its-analysis.R

mv data/json/* data/$PROJECT/

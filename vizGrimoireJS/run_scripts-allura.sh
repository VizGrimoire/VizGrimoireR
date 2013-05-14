#!/bin/bash
#$SCMdb = SCM database
#$MLSdb = MLS database
#$ITSdb = ITS database

# Example: ./run_scripts.sh dic_cvsanaly_openstack_1289_2013_04_04 dic_mlstats_openstack_1290_2013_04_04 lcanas_bicho_openstack_1291_2013_04_04
# Allura: ./run_scripts-allura.sh acs_cvsanaly_allura_1049 acs_mlstats_allura_1049 acs_bicho_allura_1049

PROJECT=allura
LOGS=allura.log

rm -rf data/json
rm -rf data/$PROJECT
mkdir -p data/json
mkdir -p data/$PROJECT

SCMdb=acs_cvsanaly_allura_1049
MLSdb=acs_mlstats_allura_1049
ITSdb=acs_bicho_allura_1049

R --vanilla --args -d $SCMdb -u root -i $SCMdb -r people -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
exit
#MLS
R --vanilla --args -d $MLSdb -u root -i $SCMdb -r repositories -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R
R --vanilla --args -d $MLSdb -u root -i $SCMdb -r countries -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R
R --vanilla --args -d $MLSdb -u root -i $SCMdb -r companies -s 2009-10-14 -e 2013-01-07 -g months < mls-analysis.R
#SCM
R --vanilla --args -d $SCMdb -u root -i $SCMdb -r repositories -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
R --vanilla --args -d $SCMdb -u root -i $SCMdb -r countries -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
R --vanilla --args -d $SCMdb -u root -i $SCMdb -r companies -s 2009-10-14 -e 2013-01-07 -g months < scm-analysis.R
#ITS
R --vanilla --args -d $ITSdb -u root -i $SCMdb -r repositories -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R
R --vanilla --args -d $ITSdb -u root -i $SCMdb -r countries -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R
R --vanilla --args -d $ITSdb -u root -i $SCMdb -r companies -s 2009-10-14 -e 2013-01-07 -g months -t allura < its-analysis.R

mv data/json/* data/$PROJECT/

## Copyright (C) 2012, 2013 Bitergia
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## This file is a part of the vizGrimoire.R package
## http://vizgrimoire.bitergia.org/
##
## Analyze and extract metrics data gathered by CVSAnalY tool
## http://metricsgrimoire.github.com/CVSAnalY
##
## Authors:
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
##
## Usage:
##  R --vanilla --args -d dbname < scr-analysis.R
## or
##  R CMD BATCH scm-analysis.R
##

library("vizgrimoire")
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

conf <- ConfFromOptParse()
SetDBChannel (database = conf$database, user = conf$dbuser, password = conf$dbpassword)

if (conf$granularity == 'years') { 
    period = 'year'
    nperiod = 365
} else if (conf$granularity == 'months') { 
    period = 'month'
    nperiod = 31
} else if (conf$granularity == 'weeks') { 
    period = 'week'
    nperiod = 7
} else if (conf$granularity == 'days'){ 
    period = 'day'
    nperiod = 1
} else {stop(paste("Incorrect period:",conf$granularity))}

# destination directory
destdir <- conf$destination
#type of analysis
reports=strsplit(conf$reports,",",fixed=TRUE)[[1]]

reviews_type <- list("submitted", "opened", "new", "inprogress", "closed", "merged", "abandoned")

evaluations_type <- list("verified", "approved", "codereview", "submitted")
#########
#EVOLUTIONARY DATA
#########

print ("ANALYSIS PER TYPE OF REVIEW")
reviews.evol = NA
for (analysis in reviews_type)
{   
    data = EvolReviews(period, conf$startdate, conf$enddate, analysis) 
    data <- completePeriodIds(data, conf$granularity, conf)
    if (analysis == reviews_type[[1]]) reviews.evol = data
    else reviews.evol = merge(reviews.evol, data, all = TRUE)
}
# createJSON(reviews.evol, paste(destdir,"/scr-reviews-evolutionary.json", sep=''))

print ("ANALYSIS PER TYPE OF EVALUATION AT PATCH LEVEL")
evaluations.evol = NA
for (analysis in evaluations_type)
{
    data = EvolEvaluations(period, conf$startdate, conf$enddate, analysis)
    data <- completePeriodIds(data, conf$granularity, conf)
    if (analysis == evaluations_type[[1]]) evaluations.evol = data
    else evaluations.evol = merge(evaluations.evol, data, all = TRUE)
}
# createJSON(evaluations.evol, paste(destdir,"/scr-patches-evolutionary.json", sep=''))
# We have submitted in both data frames with different values
evol <- merge(reviews.evol, evaluations.evol, by.x = "unixtime", by.y = "unixtime",all = TRUE)


print ("WAITING PER REVIEW")
waiting.review.evol = Waiting4Review(period, conf$startdate, conf$enddate)
waiting.review.evol <- completePeriodIds(waiting.review.evol, conf$granularity, conf)

waiting.submitter.evol = Waiting4Submitter(period, conf$startdate, conf$enddate)
waiting.submitter.evol <- completePeriodIds(waiting.submitter.evol, conf$granularity, conf)

waiting.evol <- merge(waiting.review.evol, waiting.submitter.evol, all=TRUE)
#createJSON(waiting.evol, paste(destdir,"/scr-waiting-evolutionary.json", sep=''))

evol <- merge(evol, waiting.evol, all = TRUE)

createJSON(evol, paste(destdir,"/scr-evolutionary.json", sep=''))


########
#ANALYSIS PER REPOSITORY
########

print("ANALYSIS PER REPOSITORY")
print(reports)
print('repositories' %in% reports)
if ('repositories' %in% reports) {
    repos  <- GetReposSRCName(conf$startdate, conf$enddate)
    repos <- repos$name
    #createJSON(repos, paste(destdir,"data/json/scr-repos.json", sep=''))

    for (repo in repos) {
        repo_name = paste("'", repo, "'", sep='')
        repo_aux = paste("", repo, "", sep='')
        print (repo_name)

        first = TRUE
        evol_data = data.frame()
        for (analysis in reviews_type)
        {
            data = EvolReviews(period, conf$startdate, conf$enddate, analysis, list("repository", repo_name))
            data <- completePeriodIds(data, conf$granularity, conf)
            data <- data[order(data$id),]
            data[is.na(data)] <- 0
            if (first) {
                evol_data = data
                first = FALSE
            }else{
               evol_data = merge(evol_data, data, all = TRUE)
            }
    

        }
        createJSON(evol_data, paste(destdir, "/",repo_aux,"-scr-reviews-evolutionary.json", sep=''))

        first = TRUE
        evol_data = data.frame()
        for (analysis in evaluations_type)
        {
            data = EvolEvaluations(period, conf$startdate, conf$enddate, analysis, list("repository", repo_name))
            data <- completePeriodIds(data, conf$granularity, conf)
            data <- data[order(data$id),]
            data[is.na(data)] <- 0
            if (first) {
                evol_data = data
                first = FALSE
            }else{
               evol_data = merge(evol_data, data, all = TRUE)
            }    
        }
        createJSON(evol_data, paste(destdir, "/",repo_aux,"-scr-patches-evolutionary.json", sep=''))

        data = Waiting4Review(period, conf$startdate, conf$enddate, conf$identities_db,  list("repository", repo_name))
        data1 <- completePeriodIds(data1, conf$granularity, conf)
        data1 <- data1[order(data1$id),]
        data1[is.na(data1)] <- 0
    
        data = Waiting4Submitter(period, conf$startdate, conf$enddate, conf$identities_db,  list("repository", repo_name))
        data <- completePeriodIds(data, conf$granularity, conf)
        data <- data[order(data$id),]
        data[is.na(data)] <- 0
        evol_data = merge(data, data1, all=TRUE)
        createJSON(evol_data, paste(destdir, "/",repo_aux,"-scr-waiting-evolutionary.json", sep=''))
    }
}

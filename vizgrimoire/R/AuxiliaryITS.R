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
## This file is a part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## AuxiliaryITS.R
##
## Queries for ITS data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Luis Cañas-Díaz <lcanas@bitergia.com>


## VizGrimoireJS ITS library
evol_closed <- function (closed_condition, period, startdate, enddate) {
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(issue_id)) AS closed,
                       COUNT(DISTINCT(pup.upeople_id)) AS closers
                FROM changes,
                     people_upeople pup
                WHERE ",closed_condition,"
                      AND pup.people_id = changes.changed_by
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)
    data <- run(query)
    print(data)
    return (data)	
}

evol_changed <- function (period, startdate, enddate) {
    # Changed and changers
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(issue_id)) AS changed,
                       COUNT(DISTINCT(pup.upeople_id)) AS changers
                FROM changes,
                     people_upeople pup
                WHERE pup.people_id = changes.changed_by
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)
    data <- run(query)
    print(data)
    return (data)	
}

evol_opened <- function (period, startdate, enddate) {
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(submitted_by) AS opened,
                       COUNT(DISTINCT(pup.upeople_id)) AS openers
                FROM issues,
                     people_upeople pup
                WHERE pup.people_id = issues.submitted_by
                      AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
                GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)
    data <- run(query)
    print(data)
    return (data)
}

its_evol_repositories <- function(period, startdate, enddate) {
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(tracker_id)) AS repositories
                FROM issues
                WHERE submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
                GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)
    data <- run(query)
    print(data)
    return (data)
}

its_evol_companies <- function(period, startdate, enddate, identities_db) {
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                           COUNT(DISTINCT(upc.company_id)) AS companies
                    FROM changes,
                         people_upeople pup,
                         ",identities_db,".upeople_companies upc
                    WHERE pup.people_id = changes.changed_by
                          AND pup.upeople_id = upc.upeople_id
                          AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                    GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)    
    data <- run(query)
    print(data)
    return (data)
}

its_people <- function() {
    q <- paste ("select id,name,email,user_id from people")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

its_static_info <- function (closed_condition, startdate, enddate) {
    ## Get some general stats from the database and url info
    ##
    q <- paste ("SELECT count(*) as tickets,
                 COUNT(distinct(pup.upeople_id)) as openers,
                 DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
                 DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date 
                 FROM issues, people_upeople pup
                 WHERE issues.submitted_by = pup.people_id
                 AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data <- run(query)
	
    q <- paste ("SELECT COUNT(DISTINCT(pup.upeople_id)) as closers
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by
                 AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                 AND ", closed_condition)
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as changers
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by
                 AND changed_on >= ",startdate," AND changed_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    q <- paste ("SELECT count(*) as opened FROM issues
                 WHERE submitted_on >= ",startdate," AND submitted_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data3 <- run(query)
    
    q <- paste ("SELECT count(distinct(issue_id)) as changed FROM changes
                 WHERE changed_on >= ",startdate," AND changed_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data4 <- run(query)
    
    q <- paste ("SELECT count(distinct(issue_id)) as closed FROM changes
                 WHERE ", closed_condition, "
                 AND changed_on >= ",startdate," AND changed_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data5 <- run(query)
    
    q <- paste ("SELECT url,name as type FROM trackers t JOIN supported_trackers s ON t.type = s.id limit 1")	
    query <- new ("Query", sql = q)
    data6 <- run(query)
    
    q <- paste ("SELECT count(*) as repositories FROM trackers")
    query <- new ("Query", sql = q)
    data7 <- run(query)
    
    agg_data = merge(data, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data3)
    agg_data = merge(agg_data, data4)
    agg_data = merge(agg_data, data5)
    agg_data = merge(agg_data, data6)
    agg_data = merge(agg_data, data7)
    return(agg_data)
}

its_static_companies  <- function(startdate, enddate, identities_db) {
    q <- paste ("SELECT COUNT(DISTINCT(upc.company_id)) AS companies
                 FROM changes,
                     people_upeople pup,
                     ",identities_db,".upeople_companies upc
                 WHERE pup.people_id = changes.changed_by
                     AND pup.upeople_id = upc.upeople_id
                     AND changed_on >= ",startdate,"
                     AND changed_on <= ",enddate,"")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)               
}


# Top
top_closers <- function(days = 0) {
    if (days == 0 ) {
        q <- paste("SELECT people.name as closers, count(changes.id) as closed
                    FROM changes,
                         people,
                         people_upeople pup
                    WHERE changes.changed_by = pup.people_id
                          AND pup.people_id = people.id
                          AND ", closed_condition, "
                    GROUP BY pup.upeople_id ORDER BY closed DESC LIMIT 10;")
    } else {
        query <- new ("Query", sql ="SELECT @maxdate:=max(changed_on) from changes limit 1;")
        data <- run(query)
        q <- paste("SELECT people.name as closers, count(changes.id) as closed
                    FROM changes,
                         people,
                         people_upeople pup
                    WHERE changes.changed_by = pup.people_id
                          AND pup.people_id = people.id
                          AND ", closed_condition, "
                          AND changes.id IN (select id from changes where DATEDIFF(@maxdate,changed_on)<",days,")
                    GROUP BY pup.upeople_id ORDER BY closed DESC LIMIT 10;")
    }
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


its_repos_name <- function() {
    # q <- paste ("select SUBSTRING_INDEX(url,'/',-1) AS name FROM trackers")
    q <- paste ("SELECT url AS name FROM trackers")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

repo_evol_closed <- function(repo, closed_condition, period, startdate, enddate){
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(issue_id)) AS closed,
                       COUNT(DISTINCT(pup.upeople_id)) AS closers
                FROM changes,
                     issues,
                     trackers,
                     people_upeople pup
                WHERE ",closed_condition,"
                      AND trackers.url=",repo,"
                      AND changes.issue_id = issues.id
                      AND issues.tracker_id = trackers.id
                      AND pup.people_id = changes.changed_by
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                      GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

repo_evol_changed <- function(repo, period, startdate, enddate){
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(changes.issue_id)) AS changed,
                       COUNT(DISTINCT(pup.upeople_id)) AS changers
                FROM changes,
                     issues,
                     trackers,
                     people_upeople pup
                WHERE trackers.url=",repo,"
                      AND changes.issue_id = issues.id
                      AND issues.tracker_id = trackers.id
                      AND pup.people_id = changes.changed_by
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

repo_evol_opened <- function(repo, period, startdate, enddate){
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(submitted_by) AS opened,
                       COUNT(DISTINCT(pup.upeople_id)) AS openers
                FROM issues,
                     trackers,
                     people_upeople pup
                WHERE trackers.url=",repo,"                      
                      AND issues.tracker_id = trackers.id
                      AND pup.people_id = issues.submitted_by
                      AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
                GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

its_company_evol_closed <- function(company_name, closed_condition, period, startdate, enddate, identities_db){
    ## q <- paste("SELECT p.id AS id,
    ##                    p.year AS year,
    ##                    p.",period," AS ",period,",
    ##                    DATE_FORMAT(p.date, '%b %Y') AS date,
    ##                    IFNULL(i.closed, 0) AS closed,
    ##                    IFNULL(i.closers, 0) AS closers
    ##             FROM ",period,"s p
    ##             LEFT JOIN(
    ##                       SELECT YEAR(changed_on) AS year,
    ##                             ",period,"(changed_on) AS ",period,",
    ##                             COUNT(DISTINCT(issue_id)) AS closed,
    ##                             COUNT(DISTINCT(pup.upeople_id)) AS closers
    ##                       FROM changes,
    ##                            people_upeople pup,
    ##                            ",identities_db,".upeople_companies upc,
    ##                            ",identities_db,".companies com
    ##                       WHERE ",closed_condition,"
    ##                             AND pup.people_id = changes.changed_by
    ##                             AND pup.upeople_id = upc.upeople_id
    ##                             AND upc.company_id = com.id
    ##                             AND com.name = ",company_name,"
    ##                             AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
    ##                       GROUP BY year,",period,") i
    ##             ON (
    ##                 p.year = i.year AND p.",period," = i.",period,")
    ##             WHERE p.date >= ",startdate," AND p.date <= ",enddate,"
    ##             ORDER BY p.id ASC;", sep="")
    
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(issue_id)) AS closed,
                       COUNT(DISTINCT(pup.upeople_id)) AS closers
                FROM changes,
                     people_upeople pup,
                     ",identities_db,".upeople_companies upc,
                     ",identities_db,".companies com    
                WHERE ",closed_condition,"
                      AND pup.people_id = changes.changed_by
                      AND pup.upeople_id = upc.upeople_id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                      AND changed_on >= upc.init
                      AND changed_on <= upc.end
                      GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")")

    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)	
}

its_company_evol_changed <- function(company_name, period, startdate, enddate, identities_db){
    ## q <- paste("SELECT p.id AS id,
    ##                    p.year AS year,
    ##                    p.",period," AS ",period,",
    ##                    DATE_FORMAT(p.date, '%b %Y') AS date,
    ##                    IFNULL(i.changed, 0) AS changed,
    ##                    IFNULL(i.changers, 0) AS changers
    ##             FROM ",period,"s p
    ##             LEFT JOIN(
    ##                       SELECT YEAR(changed_on) AS year,
    ##                             ",period,"(changed_on) AS ",period,",
    ##                             COUNT(DISTINCT(issue_id)) AS changed,
    ##                             COUNT(DISTINCT(pup.upeople_id)) AS changers
    ##                       FROM changes,
    ##                            people_upeople pup,
    ##                            ",identities_db,".upeople_companies upc,
    ##                            ",identities_db,".companies com
    ##                       WHERE pup.people_id = changes.changed_by
    ##                             AND pup.upeople_id = upc.upeople_id
    ##                             AND upc.company_id = com.id
    ##                             AND com.name = ",company_name,"
    ##                             AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
    ##                       GROUP BY year,",period,") i
    ##             ON (
    ##                 p.year = i.year AND p.",period," = i.",period,")
    ##             WHERE p.date >= ",startdate," AND p.date <= ",enddate,"
    ##             ORDER BY p.id ASC;", sep="")
    
    q <- paste("SELECT ((to_days(changed_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(DISTINCT(issue_id)) AS changed,
                       COUNT(DISTINCT(pup.upeople_id)) AS changers
                FROM changes,
                     people_upeople pup,
                     ",identities_db,".upeople_companies upc,
                     ",identities_db,".companies com    
                WHERE pup.people_id = changes.changed_by
                      AND pup.upeople_id = upc.upeople_id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                      AND changed_on >= upc.init
                      AND changed_on <= upc.end
                GROUP BY ((to_days(changed_on) - to_days(",startdate,")) div ",period,")");    
    
    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)    
}

its_company_evol_opened <- function(company_name, period, startdate, enddate, identities_db){
    ## q <- paste("SELECT p.id AS id,
    ##                    p.year AS year,
    ##                    p.",period," AS ",period,",
    ##                    DATE_FORMAT(p.date, '%b %Y') AS date,
    ##                    IFNULL(i.opened, 0) AS opened,
    ##                    IFNULL(i.openers, 0) AS openers
    ##             FROM ",period,"s p
    ##             LEFT JOIN(
    ##                      SELECT YEAR(submitted_on) AS year,
    ##                             ",period,"(submitted_on) AS ",period,",
    ##                             COUNT(submitted_by) AS opened,
    ##                             COUNT(DISTINCT(pup.upeople_id)) AS openers
    ##                      FROM issues,
    ##                           people_upeople pup,
    ##                           ",identities_db,".upeople_companies upc,
    ##                           ",identities_db,".companies com
    ##                      WHERE pup.people_id = issues.submitted_by
    ##                            AND pup.upeople_id = upc.upeople_id
    ##                            AND upc.company_id = com.id
    ##                            AND com.name = ",company_name,"
    ##                            AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
    ##                      GROUP BY year,",period,") i
    ##             ON (
    ##                 p.year = i.year AND p.",period," = i.",period,")
    ##             WHERE p.date >= ",startdate," AND p.date <= ",enddate,"
    ##             ORDER BY p.id ASC;", sep="")
    
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                       COUNT(submitted_by) AS opened,
                       COUNT(DISTINCT(pup.upeople_id)) AS openers
                FROM issues,
                     people_upeople pup,
                     ",identities_db,".upeople_companies upc,
                     ",identities_db,".companies com
                WHERE pup.people_id = issues.submitted_by
                      AND pup.upeople_id = upc.upeople_id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
                      AND submitted_on >= upc.init
                      AND submitted_on <= upc.end
                GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

its_static_info_repo <- function (repo) {
    q <- paste ("SELECT COUNT(distinct(pup.upeople_id)) as openers,
                 count(*) as opened,
                 DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
                 DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date 
                 FROM issues
                 JOIN people_upeople pup ON (pup.people_id = submitted_by)
                 JOIN trackers ON (issues.tracker_id = trackers.id)
                 WHERE trackers.url=",repo)
    query <- new ("Query", sql = q)
    data <- run(query)
    
    q <- paste ("SELECT COUNT(distinct(pup.upeople_id)) as closers,
                 count(distinct(issue_id)) as closed
                 FROM changes
                 JOIN issues ON (changes.issue_id = issues.id)
                 JOIN trackers ON (issues.tracker_id = trackers.id)
                 JOIN people_upeople pup ON (pup.people_id = changed_by)
                 WHERE ",closed_condition,"
                 AND trackers.url=",repo)
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    q <- paste ("SELECT COUNT(distinct(pup.upeople_id)) as changers,
                 count(distinct(issue_id)) as changed
                 FROM changes
                 JOIN issues ON (changes.issue_id = issues.id)
                 JOIN trackers ON (issues.tracker_id = trackers.id)
                 JOIN people_upeople pup ON (pup.people_id = changed_by)
                 WHERE trackers.url=",repo)	
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    agg_data = merge(data, data1)
    agg_data = merge(agg_data, data2)
    return(agg_data)
}

its_companies_name <- function(startdate, enddate, identities_db) {
    q <- paste ("select distinct(c.name)
                    from ",identities_db,".companies c,
                         people_upeople pup,
                         ",identities_db,".upeople_companies upc,
                         changes s
                    where c.id = upc.company_id and
                          upc.upeople_id = pup.upeople_id and
                          pup.people_id = s.changed_by and
                          s.changed_on >", startdate, " and
                          s.changed_on <= ", enddate, "
                    group by c.name
                    order by count(distinct(s.issue_id)) desc;")
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

its_companies_name_wo_affs <- function(affs_list, startdate, enddate, identities_db) {
    #List of companies without certain affiliations
    affiliations = ""
    for (aff in affs_list){
        affiliations <- paste(affiliations, " c.name<>'",aff,"' and ",sep="")
    }
    
    q <- paste ("select distinct(c.name)
                 from ",identities_db,".companies c,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      changes s
                 where c.id = upc.company_id and
                       upc.upeople_id = pup.upeople_id and
                       pup.people_id = s.changed_by and
                       ",affiliations,"
                       s.changed_on >", startdate, " and
                       s.changed_on <= ", enddate, "
                 group by c.name
                 order by count(distinct(s.id)) desc;", sep="")
    query <- new("Query", sql = q)
    data <- run(query)
    return (data)
}



its_company_static_info <- function (company_name, startdate, enddate, identities_db) {
    ## Get some general stats from the database and url info
    ##

    q <- paste ("SELECT COUNT(DISTINCT(issues.id)) as tickets,
                        COUNT(DISTINCT(issues.id)) as opened,
                        COUNT(distinct(pup.upeople_id)) as openers,
                        DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
                        DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date
                 FROM issues,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE issues.submitted_by = pup.people_id
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND submitted_on >= ",startdate," AND submitted_on <= ",enddate,"
                       AND submitted_on >= upc.init
                       AND submitted_on <= upc.end")
    query <- new ("Query", sql = q)
    data0 <- run(query)

    q <- paste ("SELECT COUNT(DISTINCT(pup.upeople_id)) as closers,
                        COUNT(DISTINCT(issue_id)) AS closed
                 FROM changes,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE pup.people_id = changes.changed_by
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                       AND changed_on >= upc.init
                       AND changed_on <= upc.end
                       AND ", closed_condition)
    query <- new ("Query", sql = q)
    data1 <- run(query)

    q <- paste ("SELECT COUNT(distinct(issue_id)) as changed,
                        COUNT(distinct(pup.upeople_id)) as changers
                 FROM changes,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE pup.people_id = changes.changed_by
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                       AND changed_on >= upc.init
                       AND changed_on <= upc.end")
    query <- new ("Query", sql = q)
    data2 <- run(query)


    q <- paste ("SELECT count(distinct(tracker_id)) as trackers
                 FROM issues,
                      changes,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE issues.id = changes.issue_id
                       AND pup.people_id = changes.changed_by
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                       AND changed_on >= upc.init
                       AND changed_on <= upc.end")
    query <- new ("Query", sql = q)
    data3 <- run(query)
  
    
    agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data3)
    return(agg_data)
}

its_company_top_closers <- function(company_name, startdate, enddate, identities_db) {
    q <- paste("SELECT people.name as closers,
                       COUNT(DISTINCT(changes.id)) as closed
                FROM changes,
                     people,
                     people_upeople pup,
                     ",identities_db,".upeople_companies upc,
                     ",identities_db,".companies com
                WHERE ", closed_condition, "
                      AND changes.changed_by = people.id
                      AND pup.people_id = changes.changed_by
                      AND pup.upeople_id = upc.upeople_id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND changed_on >= ",startdate," AND changed_on <= ",enddate,"
                      AND changed_on >= upc.init
                      AND changed_on <= upc.end
                GROUP BY changed_by ORDER BY closed DESC LIMIT 10;")	
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


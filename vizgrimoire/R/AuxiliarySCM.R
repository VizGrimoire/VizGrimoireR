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
## AuxiliarySCM.R
##
## Queries for SCM data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>

evol_commits <- function(granularity){
      #Commits evolution
    
      q<- paste("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.commits, 0) as commits
                               from   months m
                               left join(
                                      select year(s.date) as year, 
                    month(s.date) as month, 
                    count(distinct(s.id)) as commits
                                      from   scmlog s 
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (
                                      m.year = pm.year and
                                      m.month = pm.month);")
    
      query <- new ("Query", sql = q)
      data_commits <- run(query)
      return (data_commits)
}


evol_committers <- function(granularity){
      #Committers evolution
      q <- paste ("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.committers, 0) as committers
                               from   months m
                               left join(
                                      select year(s.date) as year, 
                    month(s.date) as month, 
                    count(distinct(pup.upeople_id)) as committers
                                      from   scmlog s,
                    people_upeople pup
                                      where s.committer_id = pup.people_id 
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (
                                      m.year = pm.year and
                                      m.month = pm.month);")
    
      query <- new ("Query", sql = q)
      data_committers <- run(query)
      return (data_committers)
}

evol_authors <- function(granularity){
	# Authors evolution
      q <- paste ("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.authors, 0) as authors
                               from   months m
                               left join(
                                      select year(s.date) as year, 
                    month(s.date) as month, 
                    count(distinct(pup.upeople_id)) as authors
                                      from   scmlog s,
                    people_upeople pup
                                      where s.author_id = pup.people_id 
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (
                                      m.year = pm.year and
                                      m.month = pm.month);")
	
    query <- new ("Query", sql = q)
    data_authors <- run(query)
	return (data_authors)
}



evol_files <- function(granularity){
    
      #Files per month
      q <- paste("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.files, 0) as files
                               from   months m
                               left join(
                                      select year(s.date) as year, 
                    month(s.date) as month, 
                    count(distinct(a.file_id)) as files
                                      from   scmlog s, 
                    actions a
                                      where  a.commit_id = s.id
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (
                                      m.year = pm.year and
                                      m.month = pm.month);")
    
    
      query <- new ("Query", sql = q)
      data_files <- run(query)
      return (data_files)
}


evol_branches <- function(granularity){
    
      #Branches per month
      q <- paste("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.branches, 0) as branches
                               from   months m
                               left join(
                                      select year(s.date) as year, 
                    month(s.date) as month, 
                    count(distinct(a.branch_id)) as branches
                                      from   scmlog s, 
                    actions a
                                      where  a.commit_id = s.id
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (     
                                      m.year = pm.year and
                                      m.month = pm.month);")
    
      query <- new ("Query", sql = q)
      data_branches <- run(query)
      return (data_branches)
}


evol_repositories <- function(granularity) {
    
      # Repositories per month
      q <- paste("select m.id as id,
                                      m.year as year,
                                      m.month as month,
                                      DATE_FORMAT(m.date, '%b %Y') as date,
                                      IFNULL(pm.repositories, 0) as repositories
                               from   months m
                               left join(
                                      select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(s.repository_id)) as repositories
                                      from   scmlog s
                                      group by year(s.date),
                    month(s.date)
                                      order by year(s.date),
                    month(s.date) ) as pm
                               on (
                                      m.year = pm.year and
                                      m.month = pm.month);")
      query <- new ("Query", sql = q)
      data_repositories <- run(query)
      return (data_repositories)
}

evol_companies <- function(){	
	q <- paste("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.companies, 0) as num_companies
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(upc.company_id)) as companies
                    from   scmlog s,
                    people_upeople pup,
                    upeople_companies upc
                    where  s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end
                    group by year(s.date), month(s.date)
                    order by year(s.date), month(s.date)) 
                    as pm
                    on (  
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")	
	companies<- query(q)
	return(companies)
}

evol_info_data <- function() {
	# Get some general stats from the database
	##
	q <- paste("SELECT count(s.id) as commits, 
                    count(distinct(pup.upeople_id)) as authors, 
                    DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
                    DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date 
                    FROM scmlog s,
                    people_upeople pup
                    where s.author_id = pup.people_id;")
	query <- new("Query", sql = q)
	data0 <- run(query)
    
	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    from scmlog s,
                    people_upeople pup
                    where s.committer_id = pup.people_id ")
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	
	q <- paste("SELECT count(distinct(name)) as branches from branches")
	query <- new("Query", sql = q)
	data2 <- run(query)	
	
	q <- paste("SELECT count(distinct(file_name)) as files from files")
	query <- new("Query", sql = q)
	data3 <- run(query)	
	
	q <- paste("SELECT count(distinct(uri)) as repositories from repositories")
	query <- new("Query", sql = q)
	data4 <- run(query)	
	
	q <- paste("SELECT count(*) as actions from actions")
	query <- new("Query", sql = q)
	data5 <- run(query)	
	
	q <- paste("select uri as url,type from repositories limit 1")
	query <- new("Query", sql = q)
	data6 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/timestampdiff(month,min(s.date),max(s.date)) 
					as avg_commits_month from scmlog s")
	query <- new("Query", sql = q)
	data7 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(month,min(s.date),max(s.date)) 
					as avg_files_month from scmlog s, actions a where a.commit_id=s.id")
	query <- new("Query", sql = q)
	data8 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author 
                    from scmlog s, 
                    people_upeople pup 
                    where pup.people_id=s.author_id")
	query <- new("Query", sql = q)
	data9 <- run(query)	
	
	q <- paste("select count(distinct(s.author_id))/timestampdiff(month,min(s.date),max(s.date)) 
					as avg_authors_month from scmlog s")
	query <- new("Query", sql = q)
	data10 <- run(query)	
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(month,min(s.date),max(s.date)) as avg_committers_month 
                    from scmlog s,
                    people_upeople pup
                    where s.committer_id = pup.people_id")
	query <- new("Query", sql = q)
	data11 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author 
                    from scmlog s, 
                    actions a,
                    people_upeople pup
                    where a.commit_id=s.id and
                    s.author_id = pup.people_id")
	query <- new("Query", sql = q)
	data12 <- run(query)	
	
	agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
	agg_data = merge(agg_data, data3)
	agg_data = merge(agg_data, data4)
	agg_data = merge(agg_data, data5)
	agg_data = merge(agg_data, data6)
	agg_data = merge(agg_data, data7)
	agg_data = merge(agg_data, data8)
	agg_data = merge(agg_data, data9)
	agg_data = merge(agg_data, data10)
	agg_data = merge(agg_data, data11)
	agg_data = merge(agg_data, data12)	
	
	return (agg_data)
}

top_committers <- function(days = 0) {
      if (days == 0 ) {
            q <- "SELECT u.identifier as committers,
                count(distinct(s.id)) as commits
                          FROM scmlog s,
                               people_upeople pup,
                               upeople u
                          where s.committer_id = pup.people_id and
                pup.upeople_id = u.id
                          group by u.identifier
                          order by commits desc
	                  LIMIT 10;"
      } else {
            query <- new("Query",
                sql = "SELECT @maxdate:=max(date) from scmlog limit 1")
            data <- run(query)
            q <- paste("SELECT u.identifier as committers,
                                               count(distinct(s.id)) as commits
                                        FROM scmlog s,
                                             people_upeople pup,
                                             upeople u
                                        WHERE DATEDIFF(@maxdate,date)<",days," and
                                              s.committer_id = pup.people_id and
                                              pup.upeople_id = u.id
                                        group by u.identifier
                                        order by commits desc    
                                        LIMIT 10;")
      }
      query <- new("Query", sql = q)
      data <- run(query)
      return (data)	
}

top_files_modified <- function() {
      q <- paste("select file_name, count(commit_id) as modifications 
	                          from action_files a join files f on a.file_id = f.id 
	                          where action_type='M' group by f.id 
	                          order by modifications desc limit 10; ")	
      query <- new("Query", sql = q)
      data <- run(query)
      return (data)	
}

## TODO: Follow top_committers implementation
top_authors <- function() {
    q <- paste("SELECT u.identifier as authors,
                                     count(distinct(s.id)) as commits
                              FROM scmlog s,
                                   people_upeople pup,
                                   upeople u
                              where s.author_id = pup.people_id and
                                    pup.upeople_id = u.id
                              group by u.identifier
                              order by commits desc
	                      LIMIT 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

top_authors_year <- function(year) {
    q <- paste("SELECT u.identifier as authors,
                                     count(distinct(s.id)) as commits
                              FROM scmlog s,
                                   people_upeople pup,
                                   upeople u
                              where s.author_id = pup.people_id and
                                    pup.upeople_id = u.id and
                                    year(s.date) = ",year,"
                              group by u.identifier
                              order by commits desc
	                      LIMIT 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

people <- function() {
	q <- paste ("select id,identifier from upeople")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data);
}

companies_name <- function() {
	q <- paste ("select c.name 
                    from companies c,
                    people_upeople pup,
                    upeople_companies upc,
                    scmlog s
                    where c.id = upc.company_id and
                    upc.upeople_id = pup.upeople_id and
                    pup.people_id = s.author_id
                    group by c.name
                    order by count(distinct(s.id)) desc;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_commits <- function(company_name){		
	print (company_name)
	q <- paste("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.commits, 0) as commits
                    from  months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(s.id)) as commits
                    from   scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by year(s.date),
                    month(s.date)
                    order by year(s.date),
                    month(s.date)) as pm
                    on (
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

company_files <- function(company_name) {
	
	q <- paste ("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.files, 0) as files
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(a.file_id)) as files
                    from   scmlog s,
                    actions a,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  a.commit_id = s.id and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by year(s.date),
                    month(s.date) 
                    order by year(s.date),
                    month(s.date)) as pm
                    on (
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_authors <- function(company_name) {		
	q <- paste ("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.authors, 0) as authors
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(s.author_id)) as authors
                    from   scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date>=upc.init and 
                    s.date<=upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by year(s.date),
                    month(s.date) 
                    order by year(s.date),
                    month(s.date) ) as pm
                    on (
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_committers <- function(company_name) {		
	q <- paste ("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.committers, 0) as committers
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(s.committer_id)) as committers
                    from   scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  s.committer_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by year(s.date),
                    month(s.date) 
                    order by year(s.date),
                    month(s.date) ) as pm
                    on (
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_lines <- function(company_name) {
	
	q <- paste ("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.added_lines, 0) as added_lines,
                    IFNULL(pm.removed_lines, 0) as removed_lines
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    sum(cl.added) as added_lines,
                    sum(cl.removed) as removed_lines
                    from   commits_lines cl,
                    scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  cl.commit_id = s.id and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by year(s.date),
                    month(s.date)
                    order by year(s.date),
                    month(s.date)) as pm
                    on (
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

evol_info_data_company <- function(company_name) {
	
	# Get some general stats from the database
	##
	q <- paste("SELECT count(s.id) as commits, 
                    count(distinct(s.committer_id)) as committers,
                    count(distinct(s.author_id)) as authors,
                    DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                    DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                    FROM   scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where  s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data1 <- run(query)	
	q <- paste("SELECT count(distinct(file_id)) as files
                    from actions a,
                    scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where a.commit_id = s.id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data3 <- run(query)	
	q <- paste("SELECT count(*) as actions 
                    from actions a, 
                    scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.id = a.commit_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data5 <- run(query)	
	q <- paste("select count(s.id)/timestampdiff(month,min(s.date),max(s.date)) as avg_commits_month
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data7 <- run(query)	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(month,min(s.date),max(s.date)) as avg_files_month
                    from scmlog s, 
                    actions a,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where a.commit_id=s.id and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data8 <- run(query)	
	q <- paste("select count(distinct(s.id))/count(distinct(s.author_id)) as avg_commits_author
                    from scmlog s, 
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data9 <- run(query)	
	q <- paste("select count(distinct(s.author_id))/timestampdiff(month,min(s.date),max(s.date)) as avg_authors_month
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and 
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data10 <- run(query)	
	q <- paste("select count(distinct(a.file_id))/count(distinct(s.author_id)) as avg_files_author
                    from scmlog s, 
                    actions a,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where a.commit_id=s.id and
                    s.author_id is not null and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name)
	query <- new("Query", sql = q)
	data11 <- run(query)
	
	agg_data = merge(data1, data3)
	agg_data = merge(agg_data, data5)
	agg_data = merge(agg_data, data7)
	agg_data = merge(agg_data, data8)
	agg_data = merge(agg_data, data9)
	agg_data = merge(agg_data, data10)
	agg_data = merge(agg_data, data11)
	return (agg_data)
}

evol_info_data_companies <- function() {
	
	q <- paste ("select count(*) as companies from companies")
	query <- new("Query", sql = q)
	data13 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2006
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2006")
	query <- new("Query", sql = q)
	data14 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2009
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2009")
	query <- new("Query", sql = q)
	data15 <- run(query)
	
	q <- paste("select count(distinct(c.id)) as companies_2012
                    from scmlog s,
                    people_upeople pup,
                    upeople_companies upc,
                    companies c
                    where s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    year(s.date) = 2012")
	query <- new("Query", sql = q)
	data16 <- run(query)
	
	
	agg_data = merge(data13, data14)
	agg_data = merge(agg_data, data15)
	agg_data = merge(agg_data, data16)
	return (agg_data)
}

company_top_authors <- function(company_name) {
	
	q <- paste ("select u.identifier  as authors,
                    count(distinct(s.id)) as commits                         
                    from people p,
                    scmlog s,
                    people_upeople pup,
                    upeople u,
                    upeople_companies upc,
                    companies c
                    where  p.id = s.author_id and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and 
                    pup.upeople_id = u.id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by u.id
                    order by count(distinct(s.id)) desc
                    limit 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

company_top_authors_year <- function(company_name, year){
	
	q <- paste ("select u.identifier as authors,
                    count(distinct(s.id)) as commits                         
                    from people p,
                    scmlog s,
                    people_upeople pup,
                    upeople u,
                    upeople_companies upc,
                    companies c
                    where  p.id = s.author_id and
                    s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and 
                    pup.upeople_id = u.id and
                    s.date >= upc.init and 
                    s.date <= upc.end and
                    year(s.date)=",year," and
                    upc.company_id = c.id and
                    c.name =", company_name, "
                    group by u.id
                    order by count(distinct(s.id)) desc
                    limit 10;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)
}

evol_companies <- function(){	
	q <- paste("select m.id as id,
                    m.year as year,
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date,
                    IFNULL(pm.companies, 0) as num_companies
                    from   months m
                    left join(
                    select year(s.date) as year,
                    month(s.date) as month,
                    count(distinct(upc.company_id)) as companies
                    from   scmlog s,
                    people_upeople pup,
                    upeople_companies upc
                    where  s.author_id = pup.people_id and
                    pup.upeople_id = upc.upeople_id and
                    s.date >= upc.init and 
                    s.date <= upc.end
                    group by year(s.date),
                    month(s.date)
                    order by year(s.date),
                    month(s.date)) as pm
                    on (  
                    m.year = pm.year and
                    m.month = pm.month)
                    order by m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}

repos_name <- function() {
	q <- paste ("select name from repositories order by name;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}

repo_commits <- function(repo_name){		
	q <- paste("SELECT m.id as id, m.year as year, m.month as month,
					DATE_FORMAT(m.date, '%b %Y') as date, 
					IFNULL(pm.commits, 0) as commits
					FROM months m
					LEFT JOIN (
					SELECT year(s.date) as year, month(s.date) as month,
					COUNT(distinct(s.id)) as commits
					FROM scmlog s, repositories r
					WHERE r.name =", repo_name, " AND r.id = s.repository_id
					GROUP BY YEAR(s.date), MONTH(s.date)
					ORDER BY YEAR(s.date),
					MONTH(s.date)) 
					AS pm
					ON (m.year = pm.year and m.month = pm.month)
					ORDER BY m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}

repo_files <- function(repo_name) {		
	q <- paste("SELECT m.id as id, m.year as year, m.month as month,
					DATE_FORMAT(m.date, '%b %Y') as date, 
					IFNULL(pm.files, 0) as files
					FROM months m
					LEFT JOIN (
					SELECT year(s.date) as year, month(s.date) as month,
					COUNT(distinct(a.file_id)) as files
					FROM scmlog s, actions a, repositories r
					WHERE r.name =", repo_name, " AND r.id = s.repository_id
					AND a.commit_id = s.id
					GROUP BY YEAR(s.date), MONTH(s.date)
					ORDER BY YEAR(s.date),
					MONTH(s.date)) 
					AS pm
					ON (m.year = pm.year and m.month = pm.month)
					ORDER BY m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}


repo_committers <- function(repo_name) {
	q <- paste("SELECT m.id as id, 
                    m.year as year, 
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date, 
                    IFNULL(pm.committers, 0) as committers
                    FROM months m
                    LEFT JOIN (
                    SELECT year(s.date) as year, 
                    month(s.date) as month,
                    COUNT(distinct(pup.upeople_id)) as committers
                    FROM scmlog s, 
                    people_upeople pup, 
                    repositories r
                    WHERE r.name =", repo_name, " AND 
                    r.id = s.repository_id and
                    s.committer_id = pup.people_id
                    GROUP BY YEAR(s.date), 
                    MONTH(s.date)
                    ORDER BY YEAR(s.date),
                    MONTH(s.date)) 
                    AS pm
                    ON (m.year = pm.year and 
                    m.month = pm.month)
                    ORDER BY m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}


repo_authors <- function(repo_name) {
	q <- paste("SELECT m.id as id, 
                    m.year as year, 
                    m.month as month,
                    DATE_FORMAT(m.date, '%b %Y') as date, 
                    IFNULL(pm.authors, 0) as authors
                    FROM months m
                    LEFT JOIN (
                    SELECT year(s.date) as year, 
                    month(s.date) as month,
                    COUNT(distinct(pup.upeople_id)) as authors
                    FROM scmlog s, 
                    people_upeople pup, 
                    repositories r
                    WHERE r.name =", repo_name, " AND 
                    r.id = s.repository_id and
                    s.author_id = pup.people_id
                    GROUP BY YEAR(s.date), 
                    MONTH(s.date)
                    ORDER BY YEAR(s.date),
                    MONTH(s.date)) 
                    AS pm
                    ON (m.year = pm.year and 
                    m.month = pm.month)
                    ORDER BY m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}

repo_lines <- function(repo_name) {
	q <- paste("SELECT m.id as id, m.year as year, m.month as month,
					DATE_FORMAT(m.date, '%b %Y') as date, 
					IFNULL(pm.added_lines, 0) as added_lines,
					IFNULL(pm.removed_lines, 0) as removed_lines
					FROM months m
					LEFT JOIN (
					SELECT year(s.date) as year, month(s.date) as month,
					SUM(cl.added) as added_lines,
					SUM(cl.removed) as removed_lines
					FROM scmlog s, commits_lines cl, repositories r
					WHERE r.name =", repo_name, " AND r.id = s.repository_id
					AND cl.commit_id = s.id
					GROUP BY YEAR(s.date), MONTH(s.date)
					ORDER BY YEAR(s.date),
					MONTH(s.date)) 
					AS pm
					ON (m.year = pm.year and m.month = pm.month)
					ORDER BY m.id;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)				
}

evol_info_data_repo <- function(repo_name) {
	
	# Get some general stats from the database
	##
	q <- paste("SELECT count(s.id) as commits, 
                    count(distinct(pup.upeople_id)) as authors,
                    DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date,
                    DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date
                    FROM scmlog s, 
                    repositories r,
                    people_upeople pup
                    WHERE r.id = s.repository_id AND
                    s.author_id = pup.people_id and
                    r.name =", repo_name)
	query <- new("Query", sql = q)
	data0 <- run(query)
    
	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    FROM scmlog s, 
                    repositories r,
                    people_upeople pup
                    WHERE r.id = s.repository_id AND
                    s.committer_id = pup.people_id and
                    r.name =", repo_name)
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	
	q <- paste("SELECT count(distinct(file_id)) as files, count(*) as actions
                    FROM actions a, scmlog s, repositories r
                    WHERE a.commit_id = s.id AND
                    r.id = s.repository_id AND
                    r.name =", repo_name)
	query <- new("Query", sql = q)
	data2 <- run(query)
	
	q <- paste("select count(s.id)/timestampdiff(month,min(s.date),max(s.date)) 
					as avg_commits_month
					FROM scmlog s, repositories r
					WHERE r.id = s.repository_id AND
					r.name =", repo_name)
	query <- new("Query", sql = q)
	data3 <- run(query)
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(month,min(s.date),max(s.date)) 
					as avg_files_month
					FROM scmlog s, actions a, repositories r
					WHERE a.commit_id=s.id AND
					r.id = s.repository_id AND
					r.name =", repo_name)
	query <- new("Query", sql = q)
	data4 <- run(query)
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) AS avg_commits_author
                                       FROM scmlog s, 
                    repositories r,
                    people_upeople pup
                                       WHERE r.id = s.repository_id AND
                    s.author_id = pup.people_id and
                                       r.name =", repo_name)
	query <- new("Query", sql = q)
	data5 <- run(query)
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(month,min(s.date),max(s.date)) AS avg_authors_month
                    FROM scmlog s, 
                    repositories r,
                    people_upeople pup
                    WHERE r.id = s.repository_id AND
                    s.author_id = pup.people_id and
                    r.name =", repo_name)
	query <- new("Query", sql = q)
	data6 <- run(query)
	
	q <- paste("select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) AS avg_files_author
                    FROM scmlog s, 
                    actions a, 
                    repositories r,
                    people_upeople pup
                    WHERE a.commit_id=s.id AND
                    s.author_id = pup.people_id and
                    r.id = s.repository_id AND
                    r.name =", repo_name)
	query <- new("Query", sql = q)
	data7 <- run(query)
	
	agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
	agg_data = merge(agg_data, data3)
	agg_data = merge(agg_data, data4)
	agg_data = merge(agg_data, data5)
	agg_data = merge(agg_data, data6)
	agg_data = merge(agg_data, data7)
	return (agg_data)
}
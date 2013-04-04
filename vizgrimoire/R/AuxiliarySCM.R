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

evol_commits <- function(period, startdate, enddate){
      #Commits evolution
    
      q<- paste("select m.id as id,
                        m.year as year,
                        m.",period," as ",period,",
                        DATE_FORMAT(m.date, '%b %Y') as date,
                        IFNULL(pm.commits, 0) as commits
                 from   ",period,"s m
                 left join(
                           select year(s.date) as year, 
                                  ",period,"(s.date) as ",period,", 
                                  count(distinct(s.id)) as commits
                           from   scmlog s 
                           where  s.date >", startdate, " and
                                  s.date <= ", enddate, "
                           group by year(s.date),
                                    ",period,"(s.date)
                           order by year(s.date),
                                    ",period,"(s.date) ) as pm
                  on (
                      m.year = pm.year and
                      m.",period," = pm.",period,")
                  where m.date >= ", startdate, " and
                        m.date <= ",enddate," 
                  order by m.year,
                           m.",period," asc;", sep="")

      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                         count(distinct(s.id)) as commits
                  from   scmlog s 
                  where  s.date >", startdate, " and
                         s.date <= ", enddate,"
                         GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

    
      query <- new ("Query", sql = q)
      data_commits <- run(query)
      return (data_commits)
}


evol_committers <- function(period, startdate, enddate){
      #Committers evolution
      q <- paste ("select m.id as id,
                          m.year as year,
                          m.",period," as ",period,",
                          DATE_FORMAT(m.date, '%b %Y') as date,
                          IFNULL(pm.committers, 0) as committers
                   from   ",period,"s m
                   left join(
                             select year(s.date) as year, 
                                    ",period,"(s.date) as ",period,", 
                                    count(distinct(pup.upeople_id)) as committers
                             from   scmlog s,
                                    people_upeople pup
                             where s.committer_id = pup.people_id and
                                   s.date >", startdate, " and
                                   s.date <= ", enddate, "
                             group by year(s.date),
                                      ",period,"(s.date)
                             order by year(s.date),
                                      ",period,"(s.date) ) as pm
                   on (
                       m.year = pm.year and
                       m.",period," = pm.",period,")
                   where m.date >= ", startdate, " and
                         m.date <= ",enddate," 
                   order by m.year,
                            m.",period," asc;", sep="")
    
      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                         count(distinct(pup.upeople_id)) as committers
                  from   scmlog s,
                         people_upeople pup
                  where s.committer_id = pup.people_id and
                        s.date >", startdate, " and
                        s.date <= ", enddate, "
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")" , sep="")

      query <- new ("Query", sql = q)
      data_committers <- run(query)
      return (data_committers)
}

evol_authors <- function(period, startdate, enddate){
	# Authors evolution
      q <- paste ("select m.id as id,
                          m.year as year,
                          m.",period," as ",period,",
                          DATE_FORMAT(m.date, '%b %Y') as date,
                          IFNULL(pm.authors, 0) as authors
                   from   ",period,"s m
                   left join(
                             select year(s.date) as year, 
                                    ",period,"(s.date) as ",period,", 
                                    count(distinct(pup.upeople_id)) as authors
                             from   scmlog s,
                                    people_upeople pup
                             where s.author_id = pup.people_id and
                                   s.date >", startdate, " and
                                   s.date <= ", enddate, "
                             group by year(s.date),
                                      ",period,"(s.date)
                             order by year(s.date),
                                      ",period,"(s.date) ) as pm
                   on (
                       m.year = pm.year and
                       m.",period," = pm.",period,")
                   where m.date >= ", startdate, " and
                         m.date <= ",enddate," 
                   order by m.year,
                            m.",period," asc;", sep="")
	
       q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(pup.upeople_id)) as authors
                   from   scmlog s,
                          people_upeople pup
                   where s.author_id = pup.people_id and
                         s.date >", startdate, " and
                         s.date <= ", enddate, "
                   GROUP BY ((to_days(s.date) - to_days(",startdate,")) div ",period,")")

    query <- new ("Query", sql = q)
    data_authors <- run(query)
	return (data_authors)
}



evol_files <- function(period, startdate, enddate){
    
      #Files per ",period,"
      q <- paste("select m.id as id,
                         m.year as year,
                         m.",period," as ",period,",
                         DATE_FORMAT(m.date, '%b %Y') as date,
                         IFNULL(pm.files, 0) as files
                  from   ",period,"s m
                  left join(
                            select year(s.date) as year, 
                                   ",period,"(s.date) as ",period,", 
                                   count(distinct(a.file_id)) as files
                            from   scmlog s, 
                                   actions a
                            where  a.commit_id = s.id and
                                   s.date >", startdate, " and
                                   s.date <= ", enddate, "
                            group by year(s.date),
                                     ",period,"(s.date)
                            order by year(s.date),
                                     ",period,"(s.date) ) as pm
                  on (
                      m.year = pm.year and
                      m.",period," = pm.",period,")
                  where m.date >= ", startdate, " and
                        m.date <= ",enddate," 
                  order by m.year,
                           m.",period," asc;", sep="")

      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(a.file_id)) as files
                  from   scmlog s, 
                         actions a
                  where  a.commit_id = s.id and
                         s.date >", startdate, " and
                         s.date <= ", enddate, "                         
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")
    
      query <- new ("Query", sql = q)
      data_files <- run(query)
      return (data_files)
}


evol_branches <- function(period, startdate, enddate){
    
      #Branches per ",period,"
      q <- paste("select m.id as id,
                         m.year as year,
                         m.",period," as ",period,",
                         DATE_FORMAT(m.date, '%b %Y') as date,
                         IFNULL(pm.branches, 0) as branches
                  from   ",period,"s m
                  left join(
                            select year(s.date) as year, 
                                   ",period,"(s.date) as ",period,", 
                                   count(distinct(a.branch_id)) as branches
                            from scmlog s, 
                                 actions a
                            where  a.commit_id = s.id and
                                   s.date >", startdate, " and
                                   s.date <= ", enddate, "
                            group by year(s.date),
                                     ",period,"(s.date)
                            order by year(s.date),
                                     ",period,"(s.date) ) as pm
                  on (     
                      m.year = pm.year and
                      m.",period," = pm.",period,")
                  where m.date >= ", startdate, " and
                        m.date <= ",enddate," 
                  order by m.year,
                           m.",period," asc;", sep="")
    
       q <- paste("select ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                          count(distinct(a.branch_id)) as branches
                   from scmlog s, 
                   actions a
                   where  a.commit_id = s.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, "
                   group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

      query <- new ("Query", sql = q)
      data_branches <- run(query)
      return (data_branches)
}


evol_repositories <- function(period, startdate, enddate) {
    
      # Repositories per ",period,"
      q <- paste("select m.id as id,
                         m.year as year,
                         m.",period," as ",period,",
                         DATE_FORMAT(m.date, '%b %Y') as date,
                         IFNULL(pm.repositories, 0) as repositories
                  from   ",period,"s m
                  left join(
                            select year(s.date) as year,
                                   ",period,"(s.date) as ",period,",
                                   count(distinct(s.repository_id)) as repositories
                            from scmlog s
                            where s.date >", startdate, " and
                                  s.date <= ", enddate, "
                            group by year(s.date),
                                     ",period,"(s.date)
                            order by year(s.date),
                                     ",period,"(s.date) ) as pm
                  on (
                      m.year = pm.year and
                      m.",period," = pm.",period,")
                  where m.date >= ", startdate, " and
                        m.date <= ",enddate," 
                  order by m.year,
                           m.",period," asc;", sep="")

      q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id, 
                         count(distinct(s.repository_id)) as repositories
                  from scmlog s
                  where s.date >", startdate, " and
                        s.date <= ", enddate, "
                  group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

      query <- new ("Query", sql = q)
      data_repositories <- run(query)
      return (data_repositories)
}

evol_companies <- function(period, startdate, enddate){	
	q <- paste("select m.id as id,
                           m.year as year,
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date,
                           IFNULL(pm.companies, 0) as num_companies
                    from   ",period,"s m
                    left join(
                              select year(s.date) as year,
                                     ",period,"(s.date) as ",period,",
                                     count(distinct(upc.company_id)) as companies
                              from scmlog s,
                                   people_upeople pup,
                                   upeople_companies upc
                              where s.author_id = pup.people_id and
                                    pup.upeople_id = upc.upeople_id and
                                    s.date >= upc.init and 
                                    s.date <= upc.end and
                                    s.date >", startdate, " and
                                    s.date <= ", enddate, "
                              group by year(s.date), 
                                       ",period,"(s.date)
                              order by year(s.date), 
                                       ",period,"(s.date)) as pm
                    on (  
                        m.year = pm.year and
                        m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")	

        q <- paste("SELECT ((to_days(s.date) - to_days(",startdate,")) div ",period,") as id,
                           count(distinct(upc.company_id)) as companies
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date <= upc.end and
                          s.date >", startdate, " and
                          s.date <= ", enddate, "
                    group by ((to_days(s.date) - to_days(",startdate,")) div ",period,")", sep="")

	companies<- query(q)
	return(companies)
}

evol_info_data <- function(period, startdate, enddate) {
	# Get some general stats from the database
	##
	q <- paste("SELECT count(s.id) as commits, 
                    count(distinct(pup.upeople_id)) as authors, 
                    DATE_FORMAT (min(s.date), '%Y-%m-%d') as first_date, 
                    DATE_FORMAT (max(s.date), '%Y-%m-%d') as last_date 
                    FROM scmlog s,
                         people_upeople pup
                    where s.author_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data0 <- run(query)
    
	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    from scmlog s,
                         people_upeople pup
                    where s.committer_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	
	q <- paste("SELECT count(distinct(a.branch_id)) as branches 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data2 <- run(query)	
	
	q <- paste("SELECT count(distinct(file_id)) as files 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data3 <- run(query)	
	
	q <- paste("SELECT count(distinct(s.repository_id)) as repositories 
                    from scmlog s
                    where s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data4 <- run(query)	
	
	q <- paste("SELECT count(distinct(a.id)) as actions 
                    from actions a,
                         scmlog s
                    where a.commit_id = s.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, ";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)	
	
	q <- paste("select uri as url,type from repositories limit 1")
	query <- new("Query", sql = q)
	data6 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period," 
                    from scmlog s
                    where s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data7 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period," 
                    from scmlog s, 
                         actions a 
                    where a.commit_id=s.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data8 <- run(query)	
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) as avg_commits_author 
                    from scmlog s, 
                    people_upeople pup 
                    where pup.people_id=s.author_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data9 <- run(query)	
	
	q <- paste("select count(distinct(s.author_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period," 
                    from scmlog s
                    where s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data10 <- run(query)	
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_committers_",period," 
                    from scmlog s,
                    people_upeople pup
                    where s.committer_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
	query <- new("Query", sql = q)
	data11 <- run(query)	
	
	q <- paste("select count(distinct(a.file_id))/count(distinct(pup.upeople_id)) as avg_files_author
                    from scmlog s, 
                         actions a,
                    people_upeople pup
                    where a.commit_id=s.id and
                          s.author_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate,";", sep="")
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

top_committers <- function(days , startdate, enddate) {
      if (days == 0 ) {
            q <- paste("SELECT u.identifier as committers,
                         count(distinct(s.id)) as commits
                  FROM scmlog s,
                       people_upeople pup,
                       upeople u
                  where s.committer_id = pup.people_id and
                        pup.upeople_id = u.id and
                        s.date > ", startdate, " and
                        s.date <= ", enddate, "
                  group by u.identifier
                  order by commits desc
	          LIMIT 10;", sep="")
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
                              pup.upeople_id = u.id and
                              s.date >", startdate, " and
                              s.date <= ", enddate, "
                        group by u.identifier
                        order by commits desc    
                        LIMIT 10;")
      }
      query <- new("Query", sql = q)
      data <- run(query)
      return (data)	
}

top_files_modified <- function() {
      #FIXME: to be updated to use stardate and enddate values
      q <- paste("select file_name, count(commit_id) as modifications 
                  from action_files a join files f on a.file_id = f.id 
                  where action_type='M' 
                  group by f.id 
                  order by modifications desc limit 10; ")	
      query <- new("Query", sql = q)
      data <- run(query)
      return (data)	
}

## TODO: Follow top_committers implementation
top_authors <- function(startdate, enddate) {
    q <- paste("SELECT u.identifier as authors,
                       count(distinct(s.id)) as commits
                FROM scmlog s,
                     people_upeople pup,
                     upeople u
                where s.author_id = pup.people_id and
                      pup.upeople_id = u.id and
                      s.date >", startdate, " and
                      s.date <= ", enddate, "
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

companies_name <- function(startdate, enddate) {
	q <- paste ("select distinct(c.name)
                    from companies c,
                         people_upeople pup,
                         upeople_companies upc,
                         scmlog s
                    where c.id = upc.company_id and
                          upc.upeople_id = pup.upeople_id and
                          pup.people_id = s.author_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, "
                    group by c.name
                    order by count(distinct(s.id)) desc;")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_commits <- function(company_name, period, startdate, enddate){		
	print (company_name)
	q <- paste("select m.id as id,
                           m.year as year,
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date,
                           IFNULL(pm.commits, 0) as commits
                    from  ",period,"s m
                    left join(
                              select year(s.date) as year,
                                     ",period,"(s.date) as ",period,",
                                     count(distinct(s.id)) as commits
                              from scmlog s,
                                   people_upeople pup,
                                   upeople_companies upc,
                                   companies c
                              where  s.author_id = pup.people_id and
                                     pup.upeople_id = upc.upeople_id and
                                     s.date >= upc.init and 
                                     s.date <= upc.end and
                                     upc.company_id = c.id and
                                     c.name =", company_name, " and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                              group by year(s.date),
                                       ",period,"(s.date)
                              order by year(s.date),
                                       ",period,"(s.date)) as pm
                    on (
                        m.year = pm.year and
                        m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")

	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

company_files <- function(company_name, period, startdate, enddate) {
	
	q <- paste ("select m.id as id,
                            m.year as year,
                            m.",period," as ",period,",
                            DATE_FORMAT(m.date, '%b %Y') as date,
                            IFNULL(pm.files, 0) as files
                     from   ",period,"s m
                     left join(
                               select year(s.date) as year,
                                      ",period,"(s.date) as ",period,",
                                      count(distinct(a.file_id)) as files
                               from scmlog s,
                                    actions a,
                                    people_upeople pup,
                                    upeople_companies upc,
                                    companies c
                               where a.commit_id = s.id and
                                     s.author_id = pup.people_id and
                                     pup.upeople_id = upc.upeople_id and
                                     s.date >= upc.init and 
                                     s.date <= upc.end and
                                     upc.company_id = c.id and
                                     c.name =", company_name, " and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                               group by year(s.date),
                                     ",period,"(s.date) 
                               order by year(s.date),
                                        ",period,"(s.date)) as pm
                     on (
                         m.year = pm.year and
                         m.",period," = pm.",period,")
                     where m.date >= ", startdate, " and
                           m.date <= ",enddate," 
                     order by m.year,
                              m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_authors <- function(company_name, period, startdate, enddate) {		
	q <- paste ("select m.id as id,
                            m.year as year,
                            m.",period," as ",period,",
                            DATE_FORMAT(m.date, '%b %Y') as date,
                            IFNULL(pm.authors, 0) as authors
                     from   ",period,"s m
                     left join(
                               select year(s.date) as year,
                                      ",period,"(s.date) as ",period,",
                                      count(distinct(s.author_id)) as authors
                               from scmlog s,
                                    people_upeople pup,
                                    upeople_companies upc,
                                    companies c
                               where  s.author_id = pup.people_id and
                                      pup.upeople_id = upc.upeople_id and
                                      s.date>=upc.init and 
                                      s.date<=upc.end and
                                      upc.company_id = c.id and
                                      c.name =", company_name, " and
                                      s.date >", startdate, " and
                                      s.date <= ", enddate, "
                               group by year(s.date),
                                        ",period,"(s.date) 
                               order by year(s.date),
                                        ",period,"(s.date) ) as pm
                     on (
                         m.year = pm.year and
                         m.",period," = pm.",period,")
                     where m.date >= ", startdate, " and
                           m.date <= ",enddate," 
                     order by m.year,
                              m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_committers <- function(company_name, period, startdate, enddate) {		
	q <- paste ("select m.id as id,
                            m.year as year,
                            m.",period," as ",period,",
                            DATE_FORMAT(m.date, '%b %Y') as date,
                            IFNULL(pm.committers, 0) as committers
                     from   ",period,"s m
                     left join(
                               select year(s.date) as year,
                                      ",period,"(s.date) as ",period,",
                                      count(distinct(s.committer_id)) as committers
                               from scmlog s,
                                    people_upeople pup,
                                    upeople_companies upc,
                                    companies c
                               where  s.committer_id = pup.people_id and
                                      pup.upeople_id = upc.upeople_id and
                                      s.date >= upc.init and 
                                      s.date <= upc.end and
                                      upc.company_id = c.id and
                                      c.name =", company_name, " and
                                      s.date >", startdate, " and
                                      s.date <= ", enddate, "
                               group by year(s.date),
                                        ",period,"(s.date) 
                               order by year(s.date),
                                        ",period,"(s.date) ) as pm
                     on (
                         m.year = pm.year and
                         m.",period," = pm.",period,")
                     where m.date >= ", startdate, " and
                           m.date <= ",enddate," 
                     order by m.year,
                              m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)
}

company_lines <- function(company_name, period, startdate, enddate) {
	
	q <- paste ("select m.id as id,
                            m.year as year,
                            m.",period," as ",period,",
                            DATE_FORMAT(m.date, '%b %Y') as date,
                            IFNULL(pm.added_lines, 0) as added_lines,
                            IFNULL(pm.removed_lines, 0) as removed_lines
                     from   ",period,"s m
                     left join(
                               select year(s.date) as year,
                                      ",period,"(s.date) as ",period,",
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
                                      c.name =", company_name, " and
                                      s.date >", startdate, " and
                                      s.date <= ", enddate, "
                               group by year(s.date),
                                        ",period,"(s.date)
                               order by year(s.date),
                                        ",period,"(s.date)) as pm
                     on (
                         m.year = pm.year and
                         m.",period," = pm.",period,")
                     where m.date >= ", startdate, " and
                           m.date <= ",enddate," 
                     order by m.year,
                              m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)	
}

evol_info_data_company <- function(company_name, period, startdate, enddate) {
	
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
                           s.date >", startdate, " and
                           s.date <= ", enddate, " and
                           c.name =", company_name, ";", sep="")
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          c.name =", company_name, ";", sep="")
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
                         s.date >", startdate, " and
                         s.date <= ", enddate, " and
                         c.name =", company_name,";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)	

	q <- paste("select count(s.id)/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period,"
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and
                          s.date >= upc.init and 
                          s.date <= upc.end and
                          upc.company_id = c.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data7 <- run(query)	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period,"
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          c.name =", company_name, ";", sep="")
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          c.name =", company_name, ";", sep="")
	query <- new("Query", sql = q)
	data9 <- run(query)	

	q <- paste("select count(distinct(s.author_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_authors_",period,"
                    from scmlog s,
                         people_upeople pup,
                         upeople_companies upc,
                         companies c
                    where s.author_id = pup.people_id and
                          pup.upeople_id = upc.upeople_id and 
                          s.date >= upc.init and 
                          s.date <= upc.end and
                          upc.company_id = c.id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          c.name =", company_name, ";", sep="")
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and 
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

evol_info_data_companies <- function(startdate, enddate) {
	
	q <- paste ("select count(distinct(c.id)) as companies 
                     from companies c,
                          upeople_companies upc,
                          people_upeople pup,
                          scmlog s
                     where c.id = upc.company_id and
                           upc.upeople_id = pup.upeople_id and
                           pup.people_id = s.author_id and
                           s.date >", startdate, " and
                           s.date <= ", enddate, ";", sep="") 
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

company_top_authors <- function(company_name, startdate, enddate) {
	
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
                            s.date >", startdate, " and
                            s.date <= ", enddate, " and
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

evol_companies <- function(period, startdate, enddate){	
	q <- paste("select m.id as id,
                           m.year as year,
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date,
                           IFNULL(pm.companies, 0) as num_companies
                     from   ",period,"s m
                     left join(
                               select year(s.date) as year,
                                      ",period,"(s.date) as ",period,",
                                      count(distinct(upc.company_id)) as companies
                               from   scmlog s,
                                      people_upeople pup,
                                      upeople_companies upc
                               where  s.author_id = pup.people_id and
                                      pup.upeople_id = upc.upeople_id and
                                      s.date >= upc.init and 
                                      s.date <= upc.end and
                                      s.date >", startdate, " and
                                      s.date <= ", enddate, "
                               group by year(s.date),
                                        ",period,"(s.date)
                               order by year(s.date),
                                        ",period,"(s.date)) as pm
                     on (  
                         m.year = pm.year and
                         m.",period," = pm.",period,")
                     where m.date >= ", startdate, " and
                           m.date <= ",enddate," 
                     order by m.year,
                              m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}

repos_name <- function(startdate, enddate) {
	q <- paste ("select distinct(name)
                     from repositories r,
                          scmlog s
                     where r.id = s.repository_id and
                           s.date >", startdate, " and
                           s.date <= ", enddate, "
                     order by name;")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)	
}

repo_commits <- function(repo_name, period, startdate, enddate){
	q <- paste("SELECT m.id as id, m.year as year, m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date, 
                           IFNULL(pm.commits, 0) as commits
                    FROM ",period,"s m
                    LEFT JOIN (
                               SELECT year(s.date) as year, 
                                      ",period,"(s.date) as ",period,",
                                      COUNT(distinct(s.id)) as commits
                               FROM scmlog s, repositories r
                               WHERE r.name =", repo_name, " AND 
                                     r.id = s.repository_id and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                               GROUP BY YEAR(s.date), 
                                        ",period,"(s.date)
                               ORDER BY YEAR(s.date),
                                        ",period,"(s.date)) AS pm
                    ON (m.year = pm.year and 
                        m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}

repo_files <- function(repo_name, period, startdate, enddate) {
	q <- paste("SELECT m.id as id, m.year as year, m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date, 
                           IFNULL(pm.files, 0) as files
                    FROM ",period,"s m
                    LEFT JOIN (
                               SELECT year(s.date) as year, ",period,"(s.date) as ",period,",
                                      COUNT(distinct(a.file_id)) as files
                               FROM scmlog s, actions a, repositories r
                               WHERE r.name =", repo_name, " AND r.id = s.repository_id and
                                     a.commit_id = s.id and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                               GROUP BY YEAR(s.date), ",period,"(s.date)
                               ORDER BY YEAR(s.date),
                                        ",period,"(s.date)) AS pm
                    ON (m.year = pm.year and m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)		
}


repo_committers <- function(repo_name, period, startdate, enddate) {
	q <- paste("SELECT m.id as id, 
                           m.year as year, 
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date, 
                           IFNULL(pm.committers, 0) as committers
                    FROM ",period,"s m
                    LEFT JOIN (
                              SELECT year(s.date) as year, 
                                     ",period,"(s.date) as ",period,",
                                     COUNT(distinct(pup.upeople_id)) as committers
                              FROM scmlog s, 
                                   people_upeople pup, 
                                   repositories r
                              WHERE r.name =", repo_name, " AND 
                                    r.id = s.repository_id and
                                    s.committer_id = pup.people_id and
                                    s.date >", startdate, " and
                                    s.date <= ", enddate, "
                              GROUP BY YEAR(s.date), 
                                       ",period,"(s.date)
                              ORDER BY YEAR(s.date),
                                       ",period,"(s.date)) AS pm
                    ON (m.year = pm.year and 
                        m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}


repo_authors <- function(repo_name, period, startdate, enddate) {
	q <- paste("SELECT m.id as id, 
                           m.year as year, 
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date, 
                           IFNULL(pm.authors, 0) as authors
                    FROM ",period,"s m
                    LEFT JOIN (
                               SELECT year(s.date) as year, 
                                      ",period,"(s.date) as ",period,",
                                      COUNT(distinct(pup.upeople_id)) as authors
                               FROM scmlog s, 
                                    people_upeople pup, 
                                    repositories r
                               WHERE r.name =", repo_name, " AND 
                                     r.id = s.repository_id and
                                     s.author_id = pup.people_id and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                               GROUP BY YEAR(s.date), 
                                        ",period,"(s.date)
                               ORDER BY YEAR(s.date),
                                        ",period,"(s.date)) AS pm
                    ON (m.year = pm.year and 
                        m.",period," = pm.",period,")
                    where m.date >= ", startdate, " and
                          m.date <= ",enddate," 
                    order by m.year,
                             m.",period," asc;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)			
}

repo_lines <- function(repo_name, period, startdate, enddate) {
	q <- paste("SELECT m.id as id, 
                           m.year as year, 
                           m.",period," as ",period,",
                           DATE_FORMAT(m.date, '%b %Y') as date, 
                           IFNULL(pm.added_lines, 0) as added_lines,
                           IFNULL(pm.removed_lines, 0) as removed_lines
                    FROM ",period,"s m
                    LEFT JOIN (
                               SELECT year(s.date) as year, ",period,"(s.date) as ",period,",
                                      SUM(cl.added) as added_lines,
                                      SUM(cl.removed) as removed_lines
                               FROM scmlog s, commits_lines cl, repositories r
                               WHERE r.name =", repo_name, " AND 
                                     r.id = s.repository_id and
                                     cl.commit_id = s.id and
                                     s.date >", startdate, " and
                                     s.date <= ", enddate, "
                               GROUP BY YEAR(s.date), 
                                        ",period,"(s.date)
                               ORDER BY YEAR(s.date),
					",period,"(s.date)) AS pm
                               ON (m.year = pm.year and 
                                   m.",period," = pm.",period,")
                               ORDER BY m.id;", sep="")
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)				
}

evol_info_data_repo <- function(repo_name, period, startdate, enddate) {
	
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data0 <- run(query)

	q <- paste("SELECT count(distinct(pup.upeople_id)) as committers
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.committer_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data1 <- run(query)
    
	q <- paste("SELECT count(distinct(file_id)) as files, 
                           count(*) as actions
                    FROM actions a, 
                         scmlog s, 
                         repositories r
                    WHERE a.commit_id = s.id AND
                          r.id = s.repository_id AND
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name,";", sep="")
	query <- new("Query", sql = q)
	data2 <- run(query)
	
	q <- paste("select count(s.id)/timestampdiff(",period,",min(s.date),max(s.date)) as avg_commits_",period,"
                    FROM scmlog s, 
                         repositories r
                    WHERE r.id = s.repository_id AND
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data3 <- run(query)
	
	q <- paste("select count(distinct(a.file_id))/timestampdiff(",period,",min(s.date),max(s.date)) as avg_files_",period,"
                    FROM scmlog s, 
                         actions a, 
                         repositories r
                    WHERE a.commit_id=s.id AND
                          r.id = s.repository_id AND
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data4 <- run(query)
	
	q <- paste("select count(distinct(s.id))/count(distinct(pup.upeople_id)) AS avg_commits_author
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.author_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name, ";", sep="")
	query <- new("Query", sql = q)
	data5 <- run(query)
	
	q <- paste("select count(distinct(pup.upeople_id))/timestampdiff(",period,",min(s.date),max(s.date)) AS avg_authors_",period,"
                    FROM scmlog s, 
                         repositories r,
                         people_upeople pup
                    WHERE r.id = s.repository_id AND
                          s.author_id = pup.people_id and
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and 
                          r.name =", repo_name, ";", sep="")
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
                          s.date >", startdate, " and
                          s.date <= ", enddate, " and
                          r.name =", repo_name, ";", sep="")
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

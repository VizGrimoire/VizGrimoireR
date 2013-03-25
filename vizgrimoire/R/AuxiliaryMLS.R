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
## Auxiliary.R
##
## Auxiliary code for the classes in the package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>

get.monthly <- function () {
      ## Sent messages
      q <- paste("SELECT year(first_date) * 12 + month(first_date) AS id,
	                year(first_date) AS year,
		            month(first_date) AS month,
		            DATE_FORMAT (first_date, '%b %Y') as date,
		            count(message_ID) AS sent
		          FROM messages
		          GROUP BY year,month
		          ORDER BY year,month")
      query <- new ("Query", sql = q)
      sent_monthly <- run(query)
	
      ## Senders
      q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
		             year(first_date) AS year,
		             month(first_date) AS month,
		             DATE_FORMAT (first_date, '%b %Y') as date,
		             count(distinct(email_address)) AS senders
		           FROM messages
		           JOIN messages_people on (messages_people.message_id = messages.message_ID)
		           WHERE type_of_recipient='From'
		           GROUP BY year,month
		           ORDER BY year,month")
      query <- new ("Query", sql = q)
      senders_monthly <- run(query)
      
      # repositories
      field = "mailing_list"
      q <- paste ("select distinct(mailing_list) from messages")
      query <- new ("Query", sql = q)
      mailing_lists <- run(query)
      
      if (is.na(mailing_lists$mailing_list)) {
	          field = "mailing_list_url"
      }		
      q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
				     year(first_date) AS year,
				     month(first_date) AS month,
				     DATE_FORMAT (first_date, '%b %Y') as date,
				     count(DISTINCT(",field,")) AS repositories
				   FROM messages
				   GROUP BY year,month
				   ORDER BY year,month")
      query <- new ("Query", sql = q)
      repos_monthly <- run(query)
      
      # countries
      q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
                     year(first_date) AS year,
                     month(first_date) AS month,
                     DATE_FORMAT (first_date, '%b %Y') as date,
                     count(DISTINCT(country)) AS countries
                     FROM messages m
                   JOIN messages_people mp ON mp.message_ID=m.message_id
                   JOIN people p ON mp.email_address = p.email_address
                   GROUP BY year,month
                   ORDER BY year,month")
      print(q)
      query <- new ("Query", sql = q)
      countries_monthly <- run(query)
      
      mls_monthly <- completeZeroMonthly (merge (sent_monthly, senders_monthly, all = TRUE))
      mls_monthly <- completeZeroMonthly (merge (mls_monthly, repos_monthly, all = TRUE))
      mls_monthly <- completeZeroMonthly (merge (mls_monthly, countries_monthly, all = TRUE))
      mls_monthly[is.na(mls_monthly)] <- 0
      return (mls_monthly)
}

analyze.monthly.list <- function (listname) {
    
    field = "mailing_list"
    listname_file = gsub("/","_",listname)
    
    if(length(i <- grep("http",listname))) {
        field = "mailing_list_url"
        cat(listname, " is a URL\n")
    }
    
    ## Messages sent	
    q <- paste("SELECT year(first_date) * 12 + month(first_date) AS id,
	              year(first_date) AS year,
	              month(first_date) AS month,
		          DATE_FORMAT (first_date, '%b %Y') as date,
	              count(message_ID) AS sent
	            FROM messages WHERE ",field,"='",listname,"'
		        GROUP BY year,month
		        ORDER BY year,month",sep = '') 
    query <- new ("Query", sql = q)
    sent_monthly <- run(query)	
    ##print (sent_monthly)
	
    ## All subjects	
    q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	                               year(first_date) AS year,
	                               month(first_date) AS month,
	                               DATE_FORMAT (first_date, '%b %Y') as date,
	                               subject
	                             FROM messages  WHERE ",field,"='",listname,"'
	                             ORDER BY year,month", sep = '')
    query <- new ("Query", sql = q)
    subjects_monthly <- run(query)
	
    ## Senders
    q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	               year(first_date) AS year,
	               month(first_date) AS month,
	               DATE_FORMAT (first_date, '%b %Y') as date,
	               COUNT(distinct(email_address)) AS senders
	             FROM messages
	             JOIN messages_people on (messages_people.message_id = messages.message_ID)
	             WHERE type_of_recipient='From' AND ",field,"='",listname,"'
	             GROUP BY year,month
	             ORDER BY year,month", sep = '')
    query <- new ("Query", sql = q)
    senders_monthly <- run(query)
    
	## TODO: this query not sure if it is correct. Not same results in VizGrimoireJS
    ## All people monthly
    q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	               year(first_date) AS year,
	               month(first_date) AS month,
	               DATE_FORMAT (first_date, '%b %Y') as date,
	               email_address
	             FROM messages
	             JOIN messages_people on (messages_people.message_id = messages.message_ID)
	             WHERE type_of_recipient='From' AND ",field,"='",listname,"'
	             ORDER BY year,month", sep = '')
    query <- new ("Query", sql = q)
    emails_monthly <- run(query)		
    
	mls_monthly <- completeZeroMonthly (merge (sent_monthly, senders_monthly, all = TRUE))
	mls_monthly[is.na(mls_monthly)] <- 0
	# TODO: Multilist approach. We will obsolete it in future
	createJSON (mls_monthly, paste("data/json/mls-",listname_file,"-evolutionary.json",sep=''))
	# Multirepos filename
	createJSON (mls_monthly, paste("data/json/",listname_file,"-mls-evolutionary.json",sep=''))
	# createJSON (subjects_monthly, paste("data/json/mls-",listname,"-subjects-evolutionary.json",sep=''))
	createJSON (emails_monthly, paste("data/json/mls-",listname_file,"-emails-evolutionary.json",sep=''))
	
	
    ## Get some general stats from the database
    ##
    q <- paste ("SELECT count(*) as sent,
                   DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
                   DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date,
                   COUNT(DISTINCT(email_address)) as senders
                 FROM messages 
	             JOIN messages_people on (messages_people.message_id = messages.message_ID)
                 WHERE ",field,"='",listname,"'",sep='')
    query <- new ("Query", sql = q)
    data <- run(query)
	# TODO: Multilist approach. We will obsolete it in future
	createJSON (data, paste("data/json/mls-",listname_file,"-static.json",sep=''))
	# Multirepos filename
	createJSON (data, paste("data/json/",listname_file,"-mls-static.json",sep=''))
}


mls_static_info <- function () {
	q <- paste ("SELECT count(*) as sent,
					DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
					DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date
					FROM messages")
	query <- new ("Query", sql = q)
	num_msg <- run(query)
	
	q <- paste ("SELECT count(*) as senders from people")
	query <- new ("Query", sql = q)
	num_ppl <- run(query)
	
	# num repositories
	field = "mailing_list"
	q <- paste ("select distinct(mailing_list) from messages")
	query <- new ("Query", sql = q)
	mailing_lists <- run(query)
	
	if (is.na(mailing_lists$mailing_list)) {
		field = "mailing_list_url"
	}
	q <- paste("SELECT COUNT(DISTINCT(",field,")) AS repositories FROM messages")
	query <- new ("Query", sql = q)
	num_repos <- run(query)
	
	q <- paste("SELECT mailing_list_url as url FROM mailing_lists limit 1")
	query <- new ("Query", sql = q)
	repo_info <- run(query)
	
	agg_data = merge(num_msg,num_ppl)
	agg_data = merge(agg_data, num_repos)
	agg_data = merge(agg_data, repo_info)
	return (agg_data)
}

analyze.monthly.mls.countries <- function (country) {           		
    # Sent and sender time series evol	
	q <- paste("SELECT year(first_date) * 12 + month(first_date) AS id,
                  year(first_date) AS year,
                  month(first_date) AS month,
                  DATE_FORMAT (first_date, '%b %Y') as date,
                  count(m.message_ID) AS sent,
                  count(distinct(p.email_address)) AS senders
                FROM messages m
                JOIN messages_people mp ON mp.message_ID=m.message_id
                JOIN people p ON mp.email_address = p.email_address
                WHERE country='",country,"'
                GROUP BY year,month
                ORDER BY year,month",sep = '')
	query <- new ("Query", sql = q)
	evol_monthly <- run(query)
    if (country == "") country ="Unknown"
    createJSON (evol_monthly, paste("data/json/",country,"-mls-evolutionary.json",sep=''))
   
    ## Get some general stats from mls
    q <- paste ("SELECT count(m.message_ID) as sent,
                   DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
                   DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date,
                   COUNT(DISTINCT(p.email_address)) as senders
                 FROM messages m
                 JOIN messages_people mp on (mp.message_id = m.message_ID)
                 JOIN people p ON mp.email_address = p.email_address
                 WHERE country='",country,"'",sep='')
    query <- new ("Query", sql = q)
    data <- run(query)
    createJSON (data, paste("data/json/",country,"-mls-static.json",sep=''))
}

top_senders <- function(days = 0) {
  	if (days == 0 ) {
    	q <- "SELECT email_address as senders, count(m.message_id) as sent 
	  			FROM messages m
          		JOIN messages_people m_p on m_p.message_id=m.message_ID 
	  			GROUP by email_address ORDER BY sent DESC LIMIT 10;"
  	} else {
    	query <- new ("Query",
                sql = "SELECT @maxdate:=max(first_date) from messages limit 1")
    	data <- run(query)
    	q <- paste("SELECT email_address as senders, count(m.message_id) as sent 
		                FROM messages m join messages_people m_p on m_p.message_id=m.message_ID
 		                WHERE DATEDIFF(@maxdate,first_date)<",days," 
		                GROUP by email_address ORDER BY sent DESC LIMIT 10;")		
  	}
	query <- new ("Query", sql = q)
	data <- run(query)
	return (data)
}
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

analyze.monthly.mls.countries <- function (country) {
           		
	## Messages sent	
	q <- paste("SELECT year(first_date) * 12 + month(first_date) AS id, 
                year(first_date) AS year,
                month(first_date) AS month,
                DATE_FORMAT (first_date, '%b %Y') as date,
                count(m.message_ID) AS sent
                FROM messages m
                JOIN messages_people mp ON mp.message_ID=m.message_id
                JOIN people p ON mp.email_address = p.email_address					  
                WHERE country='",country,"'
                GROUP BY year,month
                ORDER BY year,month",sep = '') 
	print(q)
	query <- new ("Query", sql = q)
	sent_monthly <- run(query)	
	print (sent_monthly)
	## 
	## ## All subjects	
	## q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	##                 year(first_date) AS year,
	##                 month(first_date) AS month,
	##                 DATE_FORMAT (first_date, '%b %Y') as date,
	##                 subject
	##                 FROM messages  WHERE ",field,"='",listname,"'
	##                 ORDER BY year,month", sep = '')
	## query <- new ("Query", sql = q)
	## subjects_monthly <- run(query)
	## 
	## ## Senders
	## q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	##                 year(first_date) AS year,
	##                 month(first_date) AS month,
	##                 DATE_FORMAT (first_date, '%b %Y') as date,
	##                 count(distinct(email_address)) AS senders
	##                 FROM messages
	##                 JOIN messages_people on (messages_people.message_id = messages.message_ID)
	##                 WHERE type_of_recipient='From' AND ",field,"='",listname,"'
	##                 GROUP BY year,month
	##                 ORDER BY year,month", sep = '')
	## query <- new ("Query", sql = q)
	## senders_monthly <- run(query)
	## 
	## ## TODO: this query not sure if it is correct. Not same results in VizGrimoireJS
	## ## All people monthly
	## q <- paste ("SELECT year(first_date) * 12 + month(first_date) AS id,
	##                 year(first_date) AS year,
	##                 month(first_date) AS month,
	##                 DATE_FORMAT (first_date, '%b %Y') as date,
	##                 email_address
	##                 FROM messages
	##                 JOIN messages_people on (messages_people.message_id = messages.message_ID)
	##                 WHERE type_of_recipient='From' AND ",field,"='",listname,"'
	##                 ORDER BY year,month", sep = '')
	## query <- new ("Query", sql = q)
	## emails_monthly <- run(query)		
	## 
	## mls_monthly <- completeZeroMonthly (merge (sent_monthly, senders_monthly, all = TRUE))
	## mls_monthly[is.na(mls_monthly)] <- 0
	## # TODO: Multilist approach. We will obsolete it in future
	## createJSON (mls_monthly, paste("data/json/mls-",listname_file,"-evolutionary.json",sep=''))
	## # Multirepos filename
	## createJSON (mls_monthly, paste("data/json/",listname_file,"-mls-evolutionary.json",sep=''))
	## # createJSON (subjects_monthly, paste("data/json/mls-",listname,"-subjects-evolutionary.json",sep=''))
	## createJSON (emails_monthly, paste("data/json/mls-",listname_file,"-emails-evolutionary.json",sep=''))
	## 
	## 
	## ## Get some general stats from the database
	## ##
	## q <- paste ("SELECT count(*) as sent,
	##                 DATE_FORMAT (min(first_date), '%Y-%m-%d') as first_date,
	##                 DATE_FORMAT (max(first_date), '%Y-%m-%d') as last_date,
	##                 COUNT(DISTINCT(email_address)) as senders
	##                 FROM messages 
	##                 JOIN messages_people on (messages_people.message_id = messages.message_ID)
	##                 WHERE ",field,"='",listname,"'",sep='')
	## query <- new ("Query", sql = q)
	## data <- run(query)
	## # TODO: Multilist approach. We will obsolete it in future
	## createJSON (data, paste("data/json/mls-",listname_file,"-static.json",sep=''))
	## # Multirepos filename
	## createJSON (data, paste("data/json/",listname_file,"-mls-static.json",sep=''))
}
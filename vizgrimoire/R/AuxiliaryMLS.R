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
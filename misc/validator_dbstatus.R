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
##
## Authors:
##   Marina Doria Garcia de Cortazar <marina@bitergia.com>
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
##
## Usage:
##   R --vanilla --args -d dbname -u dbuser -p dbpassword < validator_dbstatus.R
##







library(optparse)
library(RMySQL)
library(DBI)

ConfFromOptParse <- function () {

  option_list <- list(
			make_option(c("-d", "--database"), dest="database",
			help="Database with data"),

			make_option(c("-u", "--dbuser"), dest="dbuser",
			help="Database user", default="root"),

			make_option(c("-p", "--dbpassword"), dest="dbpassword",
			help="Database user password", default=""),

			make_option(c("-t", "--dbtype"), dest="dbtype",
			help="Type of database; scm, mls, its")                      
                     )

  parser <- OptionParser(usage = "%prog [options]", option_list = option_list)
  options <- parse_args(parser)	
  if (is.null(options$database)) {	
	  print_help(parser)
	  stop("Database param is required")
  }	
  return(options)	
}
#---



conf <- ConfFromOptParse()

print(conf)

con <- dbConnect(MySQL(), dbname = conf$database, user = conf$dbuser, password = conf$dbpassword)


#This function show tables inside database and count rows. 
query<-paste("show tables")
rs<-dbSendQuery(con, query)
tables<-fetch(rs,n=-1)
  for( i in 1:nrow(tables))
  {
   query2<-paste("select count(*) from",tables[i,])
   rs2<-dbSendQuery(con, query2)
   total<-fetch(rs2,n=-1)
   query3<-paste("Total rows in",tables[i,],total)
   print(query3)
   i<-i+1
  }






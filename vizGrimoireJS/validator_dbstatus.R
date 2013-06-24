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
##   R --vanilla --args -d dbname -u dbuser -p dbpassword -v dverbose < validator_dbstatus.R
##





library(optparse)
library(DBI)
library(RMySQL)

ConfFromOptParse <- function () {

  option_list <- list(
			make_option(c("-d", "--database"), dest="database",
			help="Database with data"),

			make_option(c("-u", "--dbuser"), dest="dbuser",
			help="Database user", default="root"),

			make_option(c("-p", "--dbpassword"), dest="dbpassword",
			help="Database user password", default=""),

			make_option(c("-t", "--dbtype"), dest="dbtype",
			help="Type of database; scm, mls, its"),                     
                      
                        make_option(c("-v", "--verbose"), dest="dverbose",
                        help="Option to show more information (yes/no) ", default="no")


      )

  parser <- OptionParser(usage = "%prog [options]", option_list = option_list)
  options <- parse_args(parser)	
  if (is.null(options$database)) {	
	  print_help(parser)
	  stop("Database param is required")
  }	
  return(options)	
}


conf <- ConfFromOptParse()

print(conf)

con <- dbConnect(MySQL(), dbname = conf$database, user = conf$dbuser, password = conf$dbpassword)

query<-paste("show tables")
rs<-dbSendQuery(con, query)
all<-c()
rows<-c()
tables<-fetch(rs,n=-1)
colnames(tables)<-"names"
for( i in 1:nrow(tables))
{
  	query2<-paste("select count(*) from",tables[i,])
  	rs2<-dbSendQuery(con, query2)
  	total<-fetch(rs2,n=-1)
  	colnames(total)<-paste("total row",tables[i,])
  	rows<-c(rows,total)
  	i<-i+1
}

trow<-matrix(rows)
totalr<-data.frame(trow)
table_row<-data.frame(totalr,tables)
colnames(table_row)<-c("rows","names")





Control<-function()
{
 #This function classifies core and optional tables with number of rows.
 i<-0
 cores<-NULL
 ops<-NULL
 errs<-NULL
 print("TABLES ANALYSIS:")
  for(i in 1:nrow(table_row))
  {
    if (is.element(table_row$names[i], core)){
        co<-paste(table_row$names[i],table_row$rows[i])      
        cores<-c(cores,co) 
         i<-i+1

           }
    else if (is.element(table_row$names[i], optional)){
         op<-paste(table_row$names[i],table_row$rows[i])
           ops<-c(ops,op)
           i<-i+1
            }
    else {
           er<-paste("error; table unidentified:",table_row$names[i])
           errs<-c(errs,er) 
           i<-i+1
             } 

   
  }
  
  x<-paste("   CORE TABLE", cores)
  print(x)
  y<-paste("   OPTIONAL TABLE",ops)
  print(y)
  print(errs)

}



Compare<-function(table1,table2,value1,value2)
{
#This function compares number of rows between pair of tables
#table1=Table to compare ; value1=pk in table1 linking with the other table.  
#table2=Table to compare ; value2=pk in table2 linking with the other table.

  query<-paste("select count(", table1,".",value1,")",
  " from ",table1,
  " where ", table1,".",value1," not in (select distinct(",table2,".",value2,") from ",table2,")", sep="")
  rs<-dbSendQuery(con, query)
  missrow<-fetch(rs,n=-1)
  comp<-paste("Total missing values=",missrow)
  print(comp)
}

Errors<-function(put,table,colum)
#This function finds strings values in a given field. 
#put: value to find
#table: data.frame
#colum:field in table. 
{ query<-paste("select * from",table)
  rs<-dbSendQuery(con, query)
  tables<-fetch(rs,n=-1)
  error<-grep(put,tables[[colum]])
  
  total_error<-length(error)
  total_error<-paste("Total error:", total_error)
  print(total_error)
  
  if(conf$dverbose=="yes")
  {
  print("IN ROWS:")
  print(error)
  }
  #visual<-tables[[colum]][error]
  #print("LOOK ERRORS")
  #print(visual)
  return(error)

}


if(conf$dbtype=="scm")#SPECIAL VALIDATOR FOR SCM
{
 core<-c("actions","branches","file_copies","file_links","files","people","repositories","scmlog","tag_revisions","tags")

 optional<-c("action_files","actions_file_names","commits_lines","companies","companies_all","extra", "file_types","identities",     "months","people_upeople","upeople","upeople_companies","weeks")

 Control()

cat("\n PART 1: POSSIBLE ERRORS \n")

 print("   1.1.Table=PEOPLE Field=name") 
 
   print("      1. ERROR; @")
   error_name1<-Errors("@","people","name")

   print("      2. ERROR; root")
   people_name2<-Errors("root","people","name")

   print("      3. ERROR; bot")
   people_name3<-Errors("bot","people","name")

 print("   1.2.Table=PEOPLE Field=email") 

   print("      1. ERROR; root")
   people_email1<-Errors("root","people","email")

   print("      2. ERROR; bot")
   people_email2<-Errors("bot","people","email")

   print("      3. ERROR; miss value")
   miss_people_email<-Errors("^$|^( +)$", "people", "email")


 print("   1.3. Table=EXTRA Field=site")

   print("      1. ERROR; miss value")
   miss_extra_site<-Errors("^$|^( +)$", "extra", "site")



cat("\n PART 2: TABLES COMPARISON ; DIF BETWEEN ROWS \n")

 print("   2.1 From SCMLOG author_id to PEOPLE id") 
 compare1<-Compare("scmlog","people","author_id","id")

 print("   2.2 From SCMLOG commiter_id to PEOPLE id") 
 compare2<-Compare("scmlog","people","committer_id","id")

 print("   2.3 From PEOPLE id to PEOPLE_UPEOPLE people_id") 
 compare3<-Compare("people","people_upeople","id","people_id")

 print("   2.4 From PEOPLE_UPEOPLE people_id to UPEOPLE upeople_id") 
 compare4<-Compare("people_upeople","upeople","people_id","id")

 print("   2.5 From UPEOPLE upeople_id to UPEOPLE_COMPANIES upeople_id") 
 compare5<-Compare("upeople","upeople_companies","id","upeople_id")

}


if(conf$dbtype=="mls")#SPECIAL VALIDATOR FOR MLS

{

 core<-c("compressed_files","mailing_lists","mailing_lists_people","messages","messages_people","people","people_upeople")

 optional<-c()

 Control()

cat("\n PART 1: POSSIBLE ERRORS \n")

 print("   1.1.Table=PEOPLE Field=name") 
 
   print("      1. ERROR; @")
   error_name1<-Errors("@","people","name")

   print("      2. ERROR; root")
   people_name2<-Errors("root","people","name")

   print("      3. ERROR; bot")
   people_name3<-Errors("bot","people","name")

 print("   1.2.Table=PEOPLE Field=email_adress") 

   print("      1. ERROR; root")
   people_email1<-Errors("root","people","email_address")

   print("      2. ERROR; bot")
   people_email2<-Errors("bot","people","email_address")

   print("      3. ERROR; miss value")
   miss_people_email<-Errors("^$|^( +)$", "people", "email_address")

cat("\n PART 2: TABLES COMPARISON ; DIF BETWEEN ROWS \n")

   print("   2.1 From PEOPLE to PEOPLE_UPEOPLE") 
   compare1<-Compare("people","people_upeople","email_address","people_id")

}


if(conf$dbtype=="its")#SPECIAL VALIDATOR FOR ITS

{

	core<-c("attachments","changes","comments","issues","issues_watchers","people","people_upeople","related_to","supported_trackers","trackers","weeks")

	optional<-c("issues_ext_launchpad","issues_log_launchpad")

	Control()

cat("\n PART 1: ERRORS IN TABLES \n")

 print("   1.1.Table=PEOPLE Field=name") 

   print("      1. ERROR; @")
   error_name1<-Errors("@","people","name")

   print("      2. ERROR; root")
   people_name2<-Errors("root","people","name")

   print("      3. ERROR; bot")
   people_name3<-Errors("bot","people","name")

 print("   1.2.Table=PEOPLE Field=email") 

   print("      1. ERROR; root")
   people_email1<-Errors("root","people","email")

   print("      2. ERROR; bot")
   people_email2<-Errors("bot","people","email")

   print("      3. ERROR; miss value")
   miss_people_email<-Errors("None", "people", "email")

 cat("\n PART 2: TABLES COMPARISON ; DIF BETWEEN ROWS \n")

   print("   2.1 From PEOPLE to PEOPLE_UPEOPLE") 
   compare1<-Compare("people","people_upeople","id","people_id")


}






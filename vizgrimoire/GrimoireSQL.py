#!/usr/bin/env python

# Copyright (C) 2014 Bitergia
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# This file is a part of the vizGrimoire.R package
#
# Authors:
#     Alvaro del Castillo <acs@bitergia.com>

# SQL utilities

import MySQLdb
import logging
import re


# global vars to be moved to specific classes
cursor = None

##########
#Generic functions to obtain FROM and WHERE clauses per type of report
##########

def GetSQLReportFrom (identities_db, type_analysis):
    #generic function to generate 'from' clauses
    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    if len(type_analysis)<2: return ""

    analysis = type_analysis[0]
    value = type_analysis[1]

    tables = ""

    if (analysis):
        if (analysis == 'repository'): tables  = GetSQLRepositoriesFrom()
        elif (analysis == 'company'): tables = GetSQLCompaniesFrom(identities_db)
        elif (analysis == 'country'): tables = GetSQLCountriesFrom(identities_db)
        elif (analysis == 'domain'): tables = GetSQLDomainsFrom(identities_db)

    return (tables)


def GetSQLReportWhere (type_analysis, role):
    #generic function to generate 'where' clauses

    #"type" is a list of two values: type of analysis and value of 
    #such analysis

    if len(type_analysis)<2: return ""

    analysis = type_analysis[0]
    value = type_analysis[1]
    where = ""

    if (analysis):
        if (analysis == 'repository'): where  = GetSQLRepositoriesWhere(value)
        elif (analysis == 'company'): where = GetSQLCompaniesWhere(value, role)
        elif (analysis == 'country'): where = GetSQLCountriesWhere(value, role)
        elif (analysis == 'domain'): where = GetSQLDomainsWhere(value, role)
    return (where)

##
## METAQUERIES
##

# TODO: regexpr not adapted yet from R to Python


def GetSQLGlobal(date, fields, tables, filters, start, end):
    sql = 'SELECT '+ fields
    sql += ' FROM '+ tables
    sql += ' WHERE '+date+'>='+start+' AND '+date+'<'+end
    reg_and = re.compile("^[ ]*and", re.IGNORECASE)
    if (filters != ""):
        if (reg_and.match (filters.lower())) is not None: sql += " " + filters
        else: sql += ' AND '+filters
    return(sql)

def GetSQLPeriod(period, date, fields, tables, filters, start, end):
    kind = ['year','month','week','day']
    iso_8601_mode = 3
    if (period == 'day'):
        # Remove time so unix timestamp is start of day    
        sql = 'SELECT UNIX_TIMESTAMP(DATE('+date+')) AS unixtime, '
    elif (period == 'week'):
        sql = 'SELECT YEARWEEK('+date+','+str(iso_8601_mode)+') AS week, '
    elif (period == 'month'):
        sql = 'SELECT YEAR('+date+')*12+MONTH('+date+') AS month, '
    elif (period == 'year'):
        sql = 'SELECT YEAR('+date+')*12 AS year, '
    else:
        logging.error("PERIOD: "+period+" not supported")
        sys.exit(1)
    # sql = paste(sql, 'DATE_FORMAT (',date,', \'%d %b %Y\') AS date, ')
    sql += fields
    sql += ' FROM ' + tables
    sql = sql + ' WHERE '+date+'>='+start+' AND '+date+'<'+end
    reg_and = re.compile("^[ ]*and", re.IGNORECASE)

    if (filters != ""):
        if (reg_and.match (filters.lower())) is not None: sql += " " + filters
        else: sql += ' AND ' + filters

    if (period == 'year'):
        sql += ' GROUP BY YEAR('+date+')'
        sql += ' ORDER BY YEAR('+date+')'
    elif (period == 'month'):
        sql += ' GROUP BY YEAR('+date+'),MONTH('+date+')'
        sql += ' ORDER BY YEAR('+date+'),MONTH('+date+')'
    elif (period == 'week'):
        sql += ' GROUP BY YEARWEEK('+date+','+str(iso_8601_mode)+')'
        sql += ' ORDER BY YEARWEEK('+date+','+str(iso_8601_mode)+')'
    elif (period == 'day'):
        sql += ' GROUP BY YEAR('+date+'),DAYOFYEAR('+date+')'
        sql += ' ORDER BY YEAR('+date+'),DAYOFYEAR('+date+')'
    else:
        logging.error("PERIOD: "+period+" not supported")
        sys.exit(1)
    return(sql)

##########
# Specific FROM and WHERE clauses per type of report
##########
def GetSQLRepositoriesFrom():
    #tables necessaries for repositories
    return (" , repositories r")

def GetSQLRepositoriesWhere(repository):
    #fields necessaries to match info among tables
    filter = " and r.name ="+ repository + \
             " and r.id = s.repository_id"
    return (filter)

def GetSQLCompaniesFrom(identities_db):
    #tables necessaries for companies
    filter = " , "+identities_db+".people_upeople pup,"+\
                  identities_db+".upeople_companies upc,"+ \
                  identities_db+".companies c"
    return (filter)

def GetSQLCompaniesWhere (company, role):
    #fields necessaries to match info among tables
    filter = "and s."+role+"_id = pup.people_id "+\
             "and pup.upeople_id = upc.upeople_id "+\
             "and s.date >= upc.init "+\
             "and s.date < upc.end "+\
             "and upc.company_id = c.id "+\
             "and c.name ="+ company
    return(filter)

def GetSQLCountriesFrom (identities_db):
    #tables necessaries for companies
    filter = " , "+identities_db+".people_upeople pup," +\
                  identities_db+"upeople_countries upc",+\
                  identities_db+".countries c"
    return(filter)


def GetSQLCountriesWhere (country, role):
    #fields necessaries to match info among tables
    filter = "and s."+role+"_id = pup.people_id "+\
             "and pup.upeople_id = upc.upeople_id "+\
             "and upc.country_id = c.id "+\
             "and c.name ="+country
    return(filter)

def GetSQLDomainsFrom (identities_db):
    #tables necessaries for domains
    filter = " , "+identities_db+".people_upeople pup, "+\
                   identities_db+".upeople_domains upd "+\
                   identities_db+".domains d"
    return(filter)

def GetSQLDomainsWhere (domain, role):
    #fields necessaries to match info among tables
    filter = "and s."+role+"_id = pup.people_id " +\
             " and pup.upeople_id = upd.upeople_id "+\
             " and upd.domain_id = d.id "+\
             " and d.name ="+ domain
    return(filter)
############
#Generic functions to check evolutionary or static info and for the execution of the final query
###########

def BuildQuery (period, startdate, enddate, date_field, fields, tables, filters, evolutionary):
    # Select the way to evolutionary or aggregated dataset
    q = ""

    if (evolutionary):
         q = GetSQLPeriod(period, date_field, fields, tables, filters,
                          startdate, enddate)
    else:
         q = GetSQLGlobal(date_field, fields, tables, filters,
                          startdate, enddate)

    return(q)

def SetDBChannel (user=None, password=None, database=None,
                  host="127.0.0.1", port=3306, group=None):
  global cursor
  if (group == None):
      db = MySQLdb.connect(user=user, passwd=password,
                           db=database, host=host, port=port)
  else:
    db = MySQLdb.connect(read_default_group=group, db=database)

  cursor = db.cursor()
  cursor.execute("SET NAMES 'utf8'")

def ExecuteQuery (sql):
    result = {}
    cursor.execute(sql)
    rows = cursor.rowcount
    columns = cursor.description

    for column in columns:
        result[column[0]] = []
    if rows > 1:
        for value in cursor.fetchall():
            for (index,column) in enumerate(value):
                result[columns[index][0]].append(column)
    elif rows == 1:
        value = cursor.fetchone()
        for i in range (0, len(columns)):
            result[columns[i][0]] = value[i]
    return result 
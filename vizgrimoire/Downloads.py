## Copyright (C) 2014 Bitergia
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
## Authors:
##   Daniel Izquierdo <dizquierdo@bitergia.com>


# All of the functions found in this file expect to find a database
# with the followin format:
# Table: downloads
#       Fields:
#       

from GrimoireSQL import GetSQLGlobal, GetSQLPeriod, ExecuteQuery, BuildQuery
from GrimoireUtils import GetPercentageDiff, GetDates, completePeriodIds

def GetDownloads(period, startdate, enddate, evolutionary):
    # Generic function to obtain number of downloads 
    fields = "count(*) as downloads"
    tables = "downloads"
    filters = ""
   
    query = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(query))

def EvolDownloads(period, startdate, enddate):
    # Evolution of downloads
    return GetDownloads(period, startdate, enddate, True)

def AggDownloads(period, startdate, enddate):
    # Agg number of downloads
    return GetDownloads(period, startdate, enddate, False)

def GetPackages(period, startdate, enddate, evolutionary):
    # Generic function to obtain number of packages
    fields = "count(distinct(package)) as packages"
    tables = "downloads"
    filters = ""

    query = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(query))


def EvolPackages(period, startdate, enddate):
    # Evolution of different packages per period
    return GetPackages(period, startdate, enddate, True)

def AggPackages(period, startdate, enddate):
    # Agg number of packages in a given period
    return GetPackages(period, startdate, enddate, False)

def GetProtocols(period, startdate, enddate, evolutionary):
    # Generic function to obtain number of protocols
    fields = "count(distinct(protocol)) as protocols"
    tables = "downloads"
    filters = ""

    query = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(query))


def EvolProtocols(period, startdate, enddate):
    # Evolution of different protocols per period
    return GetProtocols(period, startdate, enddate, True)

def AggProtocols(period, startdate, enddate):
    # Agg number of protocols in a given period
    return GetProtocols(period, startdate, enddate, False)

def GetIPs(period, startdate, enddate, evolutionary):
    # Generic function to obtain number of IPs
    fields = "count(distinct(ip)) as ips"
    tables = "downloads"
    filters = ""

    query = BuildQuery(period, startdate, enddate, " date ", fields, tables, filters, evolutionary)
    return(ExecuteQuery(query))


def EvolIPs(period, startdate, enddate):
    # Evolution of different IPs per period
    return GetIPs(period, startdate, enddate, True)

def AggIPs(period, startdate, enddate):
    # Agg number of IPs in a given period
    return GetIPs(period, startdate, enddate, False)


def TopIPs(startdate, enddate, numTop):
    # Top IPs downloading packages in a given period
    query = """
            select ip, count(*) as downloads 
            from downloads
            where date >= %s and
                  date < %s
            group by ip
            order by downloads desc
            limit %s
            """ % (startdate, enddate, str(numTop))
    return ExecuteQuery(query)



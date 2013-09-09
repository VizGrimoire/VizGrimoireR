## Copyright (C) 2012 Bitergia
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
## This file is a part of the vizgrimoire R package
##
## Authors:
##   Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>

##
## Data Source class
##


setClass(
  Class = "DataSource",
  representation=representation(
    type_analysis = "list",
    startdate = "character",
    enddate = "character",
    evolutionary = "numeric"
  ),
  prototype = prototype(
    type_analysis = list(NA, NA),
    startdate = "1900-01-01",
    enddate = "2100-01-01",
    evolutionary = 1 #TRUE=1, FALSE=0
  )
)


setMethod(
  "setAnalysis", "DataSource",
  function(object, type, value) {
    # type: company, repository, people, country
    # value: any random string for each type
    object@type_analysis = list(type, value)
  }
)

setMethod(
  "getAnalysis", "DataSource",
  function(object) {
    return (object@type_analysis)
  }
)



setMethod(
  "setStartDate", "DataSource",
  function(object, startdate) {
    # date with the format: yyyy-mm-dd
    object@startdate = startdate
  }
)
setMethod(
  "getStartDate", "DataSource",
  function(object) {
    return (object@startdate)
  }
)


setMethod(
  "setEndDate", "DataSource",
  function(object, enddate) {
    # date with the format: yyyy-mm-dd
    object@enddate = enddate
  }
)
setMethod(
  "getEndDate", "DataSource",
  function(object) {
    return (object@enddate)
  }
)


setMethod(
  "setEvolutionary", "DataSource",
  function(object, evolutionary) {
    # evolutionary = TRUE or FALSE
    object@evolutionary = evolutionary
  }
)
setMethod(
  "getEvolutionary", "DataSource",
  function(object) {
    return (object@evolutionary)
  }
)


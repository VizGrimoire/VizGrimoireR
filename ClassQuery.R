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
## This file is a part of the vizGrimoire.R package
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
##
## Query class
##
## Class for SQL queries
##
setClass(Class="Query",
         representation=representation(
           sql="character"
           )
         )

# New method run, for class Query
# Returns a data frame with selected rows (as rows in the data frame)
#  and fields (as named columns in the data frame)
setGeneric (
  name= "run",
  def=function(object){standardGeneric("run")}
  )
setMethod(
  "run", "Query",
  function(object) {
    return (dbGetQuery(mychannel, object@sql))
  }
  )

# Override show method
setMethod(
  "show", "Query",
  function(object) {
    return (object@sql)
  }
  )

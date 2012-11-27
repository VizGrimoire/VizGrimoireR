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
## ITSMonthlyVarious class
##
## Class for handling various parameters related with tickets, per month
##
## This is the class that is usually instantiated to get a full monthly
##  dataset with information about the evolution of activities related to
##  tickets.

setClass(Class="ITSMonthlyVarious",
         contains="ITSMonthly",
         )

##
## Initialization is by merging objects of all the sister classes
##
## Therefore, this class is a way of getting a data frame with all
##  the relevant monthly parameters
##
setMethod(f="initialize",
          signature="ITSMonthlyVarious",
          definition=function(.Object){
            cat("~~~ ITSMonthlyVarious: initializator ~~~ \n")
            as(.Object,"data.frame") <- new ("ITSMonthlyOpen")
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyChanged"))
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyClosed"))
            as(.Object,"data.frame") <- merge (.Object,
                                               new ("ITSMonthlyLastClosed"))
            ## Complete months not present
            ## This is important, because although previous objects don't
            ## have holes, they could start / end at different months
            as(.Object,"data.frame") <- completeZeroMonthly (.Object)
            return(.Object)
          }
          )

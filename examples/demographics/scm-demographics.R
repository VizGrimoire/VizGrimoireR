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
## Usage:
##  R --no-restore --no-save < scm-demographics.R
## or
##  R CMD BATCH scm-demographics.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
#conf <- ConfFromParameters("kdevelop", "jgb", "XXX")
#SetDBChannel (conf$user, conf$password, conf$database)
conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
                           user = "root", password = NULL,
                           host = "127.0.0.1", port = 3308)
SetDBChannel (database = conf$database,
              user = conf$user, password = conf$password,
              host = conf$host, port = conf$port)
#conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git", group = "fuego")
#SetDBChannel (database = conf$database, group = conf$group)

demos <- new ("Demographics")
ages <- GetAges (demos, "2012-10-01")
JSON (ages, "/tmp/ages-2012.json")
Pyramid (ages, "/tmp/ages-2012", 4)

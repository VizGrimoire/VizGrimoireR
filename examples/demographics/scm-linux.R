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
##  R --no-restore --no-save < scm-linux.R
## or
##  R CMD BATCH scm-linux.R
##

library("vizgrimoire")

## Analyze args, and produce config params from them
## conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git",
##                            user = "root", password = NULL,
##                            host = "127.0.0.1", port = 3308)
## SetDBChannel (database = conf$database,
##               user = conf$user, password = conf$password,
##               host = conf$host, port = conf$port)
conf <- ConfFromParameters(dbschema = "dic_cvsanaly_linux_git", group = "fuego")
SetDBChannel (database = conf$database, group = conf$group)

## Requires upeople table (built with misc/unifypeople.py)

query.unique = "SELECT 
    upeople.uid as id,
    people.name as name,
    people.email as email,
    count(scmlog.id) as actions,
    MIN(scmlog.date) as firstdatestr,
    MAX(scmlog.date) as lastdatestr
FROM
    scmlog,
    people,
    upeople
where
    scmlog.author_id = upeople.id AND
    people.id = upeople.id
group by upeople.uid"

#demos <- new ("Demographics")
demos.unique <- new ("Demographics",query.unique)
for (date in c("2007-10-01", "2008-10-01", "2009-10-01",
               "2010-10-01", "2011-10-01", "2012-10-01")) {
  ProcessAges (demos.unique, date, "/tmp/linux-")
}

ages.merged <- new ("AgesMulti",
                    c(GetAges (demos.unique, "2007-10-01", 5*365),
                      GetAges (demos.unique, "2008-10-01", 4*365),
                      GetAges (demos.unique, "2009-10-01", 3*365),
                      GetAges (demos.unique, "2010-10-01", 2*365),
                      GetAges (demos.unique, "2011-10-01", 1*365),
                      GetAges (demos.unique, "2012-10-01")))

PyramidDodged (ages.merged, "/tmp/linux-pyramid-dodged")
PyramidFaceted (ages.merged, "/tmp/linux-pyramid-faceted")
Pyramid3D (ages.merged, "/tmp/linux-pyramid-3d")


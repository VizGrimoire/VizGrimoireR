#! /usr/bin/Rscript --vanilla

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
## Analyze and extract metrics data gathered by CVSAnalY tool
## http://metricsgrimoire.github.com/CVSAnalY
##
## This script analyzes data from a the Linux kernel git repository
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##
## Usage:
## scm-linux.R -d dbname -u user -p passwd -i uids_dbname \
##   --destination destdir
##
## Example:
##  LANG=en_US R_LIBS=rlib:$R_LIBS scm-linux.R -d proydb \
##  -u jgb -p XXX -i uiddb --destination destdir

library("vizgrimoire")
library("lubridate")
library("ggplot2")
library("treemap")
options(stringsAsFactors = FALSE) # avoid merge factors for toJSON 

##
## treemap.actions: Plot a treemap chart for dataframe
##
## - df: dataframe to plot. Should include as columns those in index, vSize and vColor
## - index: columns to use as levels for the treemap (higher level first)
## - vSize: column to use for size of rectangles
## - vColor: column to use for color of rectangles
## - filename: file name to write the chart to (if "", plot live)
## - height, width: for drawing to a file
##
treemap.actions <- function(df, index=c("dir", "subdir"),
                            vSize="actions",
                            vColor="actions",
                            type="value",
                            file="", height = 4, width = 6) {
  if (file != "") {
    pdf(file=file, height=height, width=width)
  }
  treemap(df, index=index, vSize=vSize, vColor=vColor, type=type)
  if (file != "") {
    dev.off()
  }
}

##
## Read configuration from command line, and connect to database
##
conf <- ConfFromOptParse()
SetDBChannel (database = conf$database,
              user = conf$dbuser, password = conf$dbpassword)

##
## Actions, authors per file, with file name and directory
##
sql <- "SELECT count(*) as actions, count(distinct(scmlog.author_id)) as authors,
substring_index(file_links.file_path,'/',1) as dir,
file_links.file_path as path
FROM actions, file_links, scmlog
WHERE actions.file_id = file_links.file_id and actions.commit_id = scmlog.id
GROUP BY file_links.file_path
ORDER BY count(*) DESC"

##
## Actions, authors per file, with file name, directory, subdirectory
##
sql = "SELECT count(*) as actions, count(distinct(scmlog.author_id)) as authors,
SUBSTRING(file_links.file_path FROM 1 FOR LOCATE('/', file_links.file_path) - 1) as dir,
IF (SUBSTRING_INDEX(file_links.file_path, '/', 2) <> file_links.file_path,
    SUBSTRING_INDEX(file_links.file_path, '/', 2),
    '') as subdir,
file_links.file_path as path
FROM actions, file_links, scmlog
WHERE actions.file_id = file_links.file_id and actions.commit_id = scmlog.id
GROUP BY path
ORDER BY actions DESC"

q <- new ("Query", sql=sql)
files.subdir.actions <- run (q)

treemap.actions(files.subdir.actions,
                index=c("dir"),
                file="/tmp/linux-treemap-actions-dir.pdf")
treemap.actions(files.subdir.actions,
                index=c("dir", "subdir"),
                file="/tmp/linux-treemap-actions-subdir.pdf")

##
## Actions, authors per subdirectory, with directory, subdirectory
##
sql = "SELECT count(*) as actions, count(distinct(scmlog.author_id)) as authors,
SUBSTRING(file_links.file_path FROM 1 FOR LOCATE('/', file_links.file_path) - 1) as dir,
IF (SUBSTRING_INDEX(file_links.file_path, '/', 2) <> file_links.file_path,
    SUBSTRING_INDEX(file_links.file_path, '/', 2),
    '') as subdir
FROM actions, file_links, scmlog
WHERE actions.file_id = file_links.file_id and actions.commit_id = scmlog.id
GROUP BY subdir
ORDER BY count(*) DESC"

q <- new ("Query", sql=sql)
subdir.actions <- run (q)

treemap.actions(subdir.actions,
                index=c("dir", "subdir"),
                vColor="authors",
                file="/tmp/linux-treemap-actions-authors-subdir.pdf")
treemap.actions(subdir.actions,
                index=c("dir", "subdir"),
                vColor="authors",
                type="dens",
                file="/tmp/linux-treemap-actions-authors-subdir-dens.pdf")

##
## Actions, authors per subdirectory and year, with directory, subdirectory
##
sql = "SELECT count(*) as actions, count(distinct(scmlog.author_id)) as authors,
SUBSTRING(file_links.file_path FROM 1 FOR LOCATE('/', file_links.file_path) - 1) as dir,
IF (SUBSTRING_INDEX(file_links.file_path, '/', 2) <> file_links.file_path,
    SUBSTRING_INDEX(file_links.file_path, '/', 2),
    '') as subdir,
YEAR(scmlog.author_date) as year
FROM actions, file_links, scmlog
WHERE actions.file_id = file_links.file_id and actions.commit_id = scmlog.id
GROUP BY subdir, year
ORDER BY count(*) DESC"

q <- new ("Query", sql=sql)
subdir.year.actions <- run (q)

subdir.2002.actions <- subset (subdir.year.actions, year=="2002")
subdir.2013.actions <- subset (subdir.year.actions, year=="2013")

treemap.actions(subdir.2002.actions,
                index=c("dir", "subdir"),
                vColor="authors",
                type="dens",
                file="/tmp/linux-treemap-actions-2002-authors-subdir.pdf")
treemap.actions(subdir.2013.actions,
                index=c("dir", "subdir"),
                vColor="authors",
                type="dens",
                file="/tmp/linux-treemap-actions-2013-authors-subdir.pdf")


##
## Demography study
##
demos.unique <- new ("Demographics", type="scm", unique=TRUE)
for (date in c("2003-03-01", "2005-03-01", "2007-03-01", "2009-03-01",
               "2011-03-01", "2013-03-01")) {
  ProcessAges (demos.unique, date, "/tmp/linux-pyramid-", periods=1)
}

ages.merged <- new ("AgesMulti",
                    c(GetAges (demos.unique, "2003-03-01", 10*365),
                      GetAges (demos.unique, "2005-03-01", 8*365),
                      GetAges (demos.unique, "2007-03-01", 6*365),
                      GetAges (demos.unique, "2009-03-01", 4*365),
                      GetAges (demos.unique, "2011-03-01", 2*365),
                      GetAges (demos.unique, "2013-03-01")))

JSON (ages.merged, "/tmp/linux-merged.json")
PyramidBar (ages.merged, position="dodge",
            "/tmp/linux-pyramid-dodge", periods=1)
PyramidBar (ages.merged, position="identity",
            "/tmp/linux-pyramid-identity", periods=1)
PyramidFaceted (ages.merged, "/tmp/linux-pyramid-faceted", periods=1)
## Uncomment to use your own HTML template
## Pyramid3D (ages.merged, dirname="/tmp/linux-pyramid-3d",
##            template="webgl-template.html")
Pyramid3D (ages.merged, dirname="/tmp/linux-pyramid-3d", periods=1)
Pyramid3D (ages.merged, interactive=TRUE, periods=1)

CloseDBChannel()

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
## This script installs the R dependencies needed by the vizgrimoire R
## libraries, downloading them from CRAN repositories.

## Some of those libraries are downloaded from CRAN as C source that
## has to be compiled. For some of the, some specific system libraries
## and development files have to be previously installed:
##  * MySQL client development files. Debian/Ubuntu pkg: libmysqlclient-dev
##      for RMySQL
##  * X11 client-side development files. Debian/Ubuntu pkg: libx11-dev
##      for rgl
##  * OpenGL development files. Debian/Ubuntu pkgs: mesa-common-dev,
##                                                  libglu1-mesa-dev
##      for rgl

## Next should be changed to your closest CRAN mirror
repos=c("http://cran.us.r-project.org")

pkgs <- c("RMySQL", "rjson", "RColorBrewer", "ggplot2", "rgl",
     "optparse", "zoo", "ISOweek")

install.packages(pkgs, repos=repos)

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

## Next should be changed to your closest CRAN mirror
repos=c("http://cran.us.r-project.org")

pkgs <- c("RMySQL", "rjson", "RColorBrewer", "ggplot2", "rgl",
     "optparse", "zoo")

install.packages(pkgs, repos=repos)

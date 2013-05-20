#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2013 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Authors :
#       Jesus M. Gonzalez-Barahona <jgb@bitergia.com>

#
# vg-github.py
#
# Simple script to retrieve data from GitHub repositories about a project
# Assumes MetricsGrimoire tools are already installed.
# If you don't know how to install them, look at
# misc/metricsgrimoire-setup.py

import argparse
import MySQLdb
import os
from subprocess import call

# Parse command line options
parser = argparse.ArgumentParser(description="""
Simple script to retrieve data from GitHub repositories about a project.
It creates MySQL databases named projectname_cvsanaly, projectname_bicho,
projectname_mls (assummes permission to create databases), but
refrains to do so if they already exist (projectname will have
/ changed to _).
It assumes MetricsGrimoire tools are already installed.
If you don't know how to install them, look at
misc/metricsgrimoire-setup.py""")
parser.add_argument("project",
                    help="GitHub project name")
parser.add_argument("--user",
                    help="MySQL user name")
parser.add_argument("--passwd",
                    help="MySQL password")
parser.add_argument("--dir",
                    help="Extraction directory (must exist). Default: /tmp")
parser.add_argument("--removedb",
                    help="Remove all databases, if present, before creating them",
                    action="store_true")
parser.add_argument("--ghuser",
                    help="GitHub user name")
parser.add_argument("--ghpasswd",
                    help="GitHub password")

args = parser.parse_args()

print args.project

dbPrefix = args.project.replace('/', '_')
if args.dir:
    dir = args.dir
else:
    dir = "/tmp"

# Open database connection and get a cursor
con = MySQLdb.connect(host='localhost', user=args.user, passwd=args.passwd) 
cursor = con.cursor()

# Configuration for tools
cvsanalyConf = {"bin": "cvsanaly2",
                "opts": [],
                "dbuser": "--db-user",
                "dbpasswd": "--db-password",
                "db": "--db-database"}
bichoConf = {"bin": "bicho",
             "opts": ["-d", "1", "-b", "github"],
             "dbuser": "--db-user-out",
             "dbpasswd": "--db-password-out",
             "db": "--db-database-out"}

conf = {"cvsanaly": cvsanalyConf,
        "bicho":    bichoConf}

# Now, actually run tools
for tool in ["cvsanaly", "bicho"]:
    # Create (and maybe remove) the database
    dbname = dbPrefix + "_" + tool
    if args.removedb:
        cursor.execute('DROP DATABASE IF EXISTS ' + dbname)
    cursor.execute('CREATE DATABASE ' + dbname)
    # Prepare options to run the tool
    print conf[tool]
    opts = [conf[tool]["bin"]]
    opts.extend (conf[tool]["opts"])
    if args.user:
        opts.extend ([conf[tool]["dbuser"], args.user])
    if args.passwd:
        opts.extend ([conf[tool]["dbpasswd"], args.passwd])
    opts.extend ([conf[tool]["db"], dbname])
    # Specific code for cvsanaly
    if tool == "cvsanaly":
        call(["git", "clone", "https://github.com/" + args.project + ".git"])
        gitdir = args.project.split('/', 1)[1]
        opts.append (dir + '/' + gitdir)
    if tool == "bicho":
        opts.extend ("--url", "http://github.com/" + args.project)
    print opts
    # Run the tool
    call(opts)

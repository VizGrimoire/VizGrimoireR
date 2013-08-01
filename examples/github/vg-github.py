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
#
# Example of how to run, for repository VizGrimoire/VizGrimoireR
# vg-github.py --user jgb --passwd XXX --dir /tmp/pp --removedb
#  --ghuser ghuser --ghpasswd XXX --vgdir ~/src/vizGrimoire
#  VizGrimoire/VizGrimoireR

import argparse
import MySQLdb
import os
import shutil
import errno
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
parser.add_argument("--nomg",
                    help="Don't run MetricsGrimoire tools",
                    action="store_true")
parser.add_argument("--ghuser",
                    help="GitHub user name")
parser.add_argument("--ghpasswd",
                    help="GitHub password")
parser.add_argument("--vgdir",
                    help="Directory with vigGrimoireR and vizGrimoireJS directories")

args = parser.parse_args()

print args.project

dbPrefix = args.project.replace('/', '_').lower()
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

rConf = {"libdir": dir + "/rlib",
         "vgrpkg": args.vgdir + "/VizGrimoireR/vizgrimoire",
         "scm-analysis": args.vgdir + \
             "/VizGrimoireR/examples/github/scm-analysis-github.R",
         "its-analysis": args.vgdir + \
             "/VizGrimoireR/examples/github/its-analysis-github.R",
         "unifypeople": args.vgdir + \
             "/VizGrimoireR/misc/unifypeople.py",
         "its2id": args.vgdir + \
             "/VizGrimoireR/misc/its2identities.py",
         "domains": args.vgdir + \
             "/VizGrimoireR/misc/domains_analysis.py"}

conf = {"cvsanaly": cvsanalyConf,
        "bicho":    bichoConf}

def RunMGTool (tool):
    """Run MetricsGrimoire tool

    tool: cvsanaly | bicho
    Uses information in global dictionary conf for deciding
    about options for the tool.
    """

    # Create (and maybe remove) the database
    dbname = dbPrefix + "_" + tool
    if args.removedb:
        cursor.execute('DROP DATABASE IF EXISTS ' + dbname)
    cursor.execute('CREATE DATABASE ' + dbname +
                   ' CHARACTER SET utf8 COLLATE utf8_unicode_ci')
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
        gitdir = args.project.split('/', 1)[1]
        call(["git", "clone", "https://github.com/" + args.project + ".git",
              dir + '/' + gitdir])
        opts.append ("--extensions=" + "CommitsLOC")
        opts.append (dir + '/' + gitdir)
    if tool == "bicho":
        opts.extend (["--url",
                     "https://api.github.com/repos/" + args.project + "/issues",
                      "--backend-user", args.ghuser,
                      "--backend-password", args.ghpasswd])
    print opts
    # Run the tool
    call(opts)
    
# Now, actually run MetricsGrimoire tools
if not args.nomg:
    for tool in ["cvsanaly", "bicho"]:
        RunMGTool (tool)

# Let's go on, now with vizGrimoire

# Install the appropriate vizgrimorer R package in a specific location
# to be used later (just in case it is not installed in standard R librdirs)
try:
    os.makedirs(rConf["libdir"])
except OSError as e:
    if e.errno == errno.EEXIST and os.path.isdir(rConf["libdir"]):
        pass
    else: 
        raise
env = os.environ.copy()
env ["R_LIBS"] = rConf["libdir"]
call (["R", "CMD", "INSTALL", rConf["vgrpkg"]], env=env)

# Run unique identities stuff
call ([rConf["unifypeople"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd, "-i", "no"])
call ([rConf["its2id"],
       "--db-database-its=" + dbPrefix + "_" + "bicho",
       "--db-database-ids=" + dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd])

# Run affiliation stuff
call ([rConf["domains"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd])

# Run the SCM (git) analysis script (ensure installed vizgrimoirer package
# is in R lib path)
os.environ["R_LIBS"] = rConf["libdir"] + ":" + os.environ.get("R_LIBS", "")
call ([rConf["scm-analysis"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd,
       "-i", dbPrefix + "_" + "cvsanaly", "--granularity", "weeks",
       "--destination", dir])

# Run the ITS (tickets) analysis script (ensure installed vizgrimoirer package
# is in R lib path)
os.environ["R_LIBS"] = rConf["libdir"] + ":" + os.environ.get("R_LIBS", "")
call ([rConf["its-analysis"], "-d", dbPrefix + "_" + "bicho",
       "-u", args.user, "-p", args.passwd,
       "-i", dbPrefix + "_" + "cvsanaly", "--granularity", "weeks",
       "--destination", dir])

# Now, let's produce an HTML dashboard for the JSON files produced in the
# previous step
# Files from vizGrimoireJS to copy:
vgjsFiles = ["vizgrimoire.min.js",
             "lib/jquery-1.7.1.min.js",
             "bootstrap/js/bootstrap.min.js",
             "vizgrimoire.css",
             "browser/custom.css",
             "bootstrap/css/bootstrap.min.css",
             "bootstrap/css/bootstrap-responsive.min.css",
             "browser/navbar.html",
             "browser/footer.html",
             "browser/refcard.html",
             "browser/project-card.html"]
# Files specific to this GitHub example:
ghBrowserfiles = ["index.html", "config.json"]

for file in vgjsFiles:
    shutil.copy(args.vgdir + "/VizGrimoireJS/" + file, dir)
for file in ghBrowserfiles:
    shutil.copy(args.vgdir + "/VizGrimoireR/examples/github/" + file, dir)

# Note: missing files:
# index.htmo, config.json

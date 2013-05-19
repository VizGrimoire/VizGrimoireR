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

args = parser.parse_args()

print args.project

dbPrefix = args.project.replace('/', '_')
if args.dir:
    dir = args.dir
else:
    dir = "/tmp"

cvsanalyOpts = ["cvsanaly2"]
bichoOpts = []
mlsOpts = []

if args.user:
    cvsanalyOpts.extend (["--db-user", args.user])
if args.passwd:
    cvsanalyOpts.extend (["--db-password", args.passwd])
cvsanalyOpts.extend (["--db-database", dbPrefix + "_cvsanaly"
])
gitdir = args.project.split('/', 1)[1]
cvsanalyOpts.append (dir + '/' + gitdir)
print cvsanalyOpts


con = MySQLdb.connect(host='localhost', user=args.user, passwd=args.passwd) 
cursor = con.cursor()

cvsanalyDB = dbPrefix + "_cvsanaly"
if args.removedb:
    cursor.execute('DROP DATABASE ' + cvsanalyDB)
cursor.execute('CREATE DATABASE ' + cvsanalyDB)

call(["git", "clone", "https://github.com/" + args.project + ".git"])
call(cvsanalyOpts)
exit()


# Create and move to the installation directory
if not os.path.exists(args.dir):
    os.makedirs(args.dir)
os.chdir(args.dir)

for tool in tools:
   if not os.path.exists(tool):
      call(["git", "clone", metricsgrimoire + tool])
   else:
      call(["git", "--git-dir=" + tool + "/.git", "pull"])

print
print "Everything should now be installed under " + args.dir
print

paths = ""
for tool in bintools:
   paths = paths + args.dir + "/" + tool + ":"
pythonpaths = ""
for tool in tools:
   pythonpaths = pythonpaths + args.dir + "/" + tool + ":"
print """Run the lines below ">>>" in your shell before running the
tools, or create a file with then and source it, or add them to
your .bashrc or equivalent.

After that, you can check if everything is ready by running:
"""

for tool in bintools:
   print tool + " --version"

env = """>>>
export PATH={paths}$PATH
export PYTHONPATH={pythonpaths}$PYTHONPATH
"""

print env.format (paths=paths, pythonpaths=pythonpaths)


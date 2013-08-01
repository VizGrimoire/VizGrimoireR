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
# metricsgrimoire-setup.py
#
# Simple script to set up some MetricsGrimoire tools from their github
# repositories, ready to work with vizGrimoireR
#

import argparse
import os
from subprocess import call

# Location of MetricsGrimoire repositories
metricsgrimoire = "https://github.com/MetricsGrimoire/"
cvsanaly = metricsgrimoire + "CVSAnalY"
repositoryhandler = metricsgrimoire + "RepositoryHandler"
bicho = metricsgrimoire + "Bicho"
mlstats = metricsgrimoire + "MailingListStats"

tools = ["CVSAnalY", "RepositoryHandler", "Bicho", "MailingListStats"]
bintools =  ["CVSAnalY", "Bicho", "MailingListStats"]

# Parse command line options
parser = argparse.ArgumentParser(description="""
Simple script to set up some MetricsGrimoire tools from their github
repositories, ready to work with vizGrimoireR.
It installs the tools in the given directory.
If the tools are already installed in the directory, they get updated.
""")
parser.add_argument("dir",
                    help="Directory to install (will be created if doesn't exist)")
args = parser.parse_args()

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
tools, or add them to your .bashrc or equivalent."""
print "You also have those lines in file " + args.dir + "/mg-paths.sh"
print """So you can also just source that file.
After any of these, you can check if everything is ready by running:
"""

for tool in bintools:
   print tool + " --version"

# Template for envirionment variables
envtemp = """export PATH={paths}$PATH
export PYTHONPATH={pythonpaths}$PYTHONPATH
"""

env = envtemp.format (paths=paths, pythonpaths=pythonpaths)

file = open(args.dir + "/mg-paths.sh", "w")
file.write(env)
file.close()

print
print ">>>"
print env

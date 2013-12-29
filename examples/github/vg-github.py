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
import urllib2
import json

# Parse command line options
parser = argparse.ArgumentParser(description="""
Simple script to retrieve data from GitHub repositories about a project.
It creates MySQL databases named projectname_cvsanaly, projectname_bicho
(assummes permission to create databases), but
refrains to do so if they already exist (projectname will have
/ changed to _).
It assumes MetricsGrimoire tools are already installed.
If you don't know how to install them, look at
misc/metricsgrimoire-setup.py""")
parser.add_argument("name",
                    help="GitHub project or user (if --isuser) name")
parser.add_argument("--isuser",
                    help="Name is the user who owns projects to analyze",
                    action="store_true")
parser.add_argument("--dbprefix",
                    help="Prefix for MySQL database (default: name argument)")
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
                    help="Directory with vigGrimoireR, vizGrimoireJS and vizGrimoireUtils directories")
parser.add_argument("--verbose",
                    help="Print out some messages about what's happening",
                    action="store_true")

args = parser.parse_args()

if args.dbprefix:
    dbPrefix = args.dbprefix.lower()
elif not args.isuser:
    dbPrefix = args.name.replace('/', '_').replace('-','_').lower()
else:
    dbPrefix = args.name.replace('-','_').lower()
if args.dir:
    dir = args.dir
else:
    dir = "/tmp"

# Root directory for the dashboard
dashboarddir = dir + "/dashboard"
# JSON directory for browser
JSONdir = dashboarddir + "/data/json"

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
             "/VizGrimoireUtils/identities/unifypeople.py",
         "ds2id": args.vgdir + \
             "/VizGrimoireUtils/identities/datasource2identities.py",
         "domains": args.vgdir + \
             "/VizGrimoireUtils/identities/domains_analysis.py"}

conf = {"cvsanaly": cvsanalyConf,
        "bicho":    bichoConf}

def prepare_db (tool, dbname):
    """Prepare MetricsGrimoire database

    tool: cvsanaly | bicho
    dbname: name of the database

    Prepares (and deletes, if args.removedb was specified) the database
    for a MetricsGrimoire tool.
    This is usually run once per tool, just before the calls to run the tools
    """

    if args.removedb:
        cursor.execute('DROP DATABASE IF EXISTS ' + dbname)
    cursor.execute('CREATE DATABASE IF NOT EXISTS ' + dbname +
                   ' CHARACTER SET utf8 COLLATE utf8_unicode_ci')

def find_repos (user):
    """Find the repos for a user.

    - user: GitHub user

    """

    repos_url = 'https://api.github.com/users/' + user + '/repos'
    res = urllib2.urlopen(repos_url)
    repos_json = res.read()
    repos = json.loads(repos_json)
    repo_names = [repo['full_name'] for repo in repos]
    return (repo_names)

def run_mgtool (tool, project, dbname):
    """Run MetricsGrimoire tool

    tool: cvsanaly | bicho
    project: GitHub project, such as VizGrimoire/VizGrimoireR
    dbname: name of the database

    Uses information in global dictionary conf for deciding
    about options for the tool.
    """

    # Prepare options to run the tool
    opts = [conf[tool]["bin"]]
    opts.extend (conf[tool]["opts"])
    if args.user:
        opts.extend ([conf[tool]["dbuser"], args.user])
    if args.passwd:
        opts.extend ([conf[tool]["dbpasswd"], args.passwd])
    opts.extend ([conf[tool]["db"], dbname])
    # Specific code for runnint cvsanaly
    if tool == "cvsanaly":
        gitdir = project.split('/', 1)[1]
        call(["git", "clone", "https://github.com/" + project + ".git",
              dir + '/' + gitdir])
        opts.append ("--extensions=" + "CommitsLOC")
        opts.append (dir + '/' + gitdir)
        if not args.verbose:
             opts.append ("--quiet")
    # Specific code for running bicho
    if tool == "bicho":
        opts.extend (["--url",
                     "https://api.github.com/repos/" + project + "/issues",
                      "--backend-user", args.ghuser,
                      "--backend-password", args.ghpasswd])
    print "Running MetricsGrimoire tool (" + tool + ")" 
    if args.verbose:
        print " ".join(opts)
    # Run the tool
    call(opts)


# Now, if there is no --nomg flag, run MetricsGrimoire tools
# If it is for a github user, get all the projects under the user name,
# and run tools on each of the.
# If it is for a single project, just run the tools on it
if not args.nomg:
    # Prepare databases
    for tool in ["cvsanaly", "bicho"]:
        dbname = dbPrefix + "_" + tool
        prepare_db (tool, dbname)
    if args.isuser:
        repos = find_repos (args.name)
    for tool in ["cvsanaly", "bicho"]:
        dbname = dbPrefix + "_" + tool
        if args.isuser:
            for repo in repos:
                run_mgtool (tool, repo, dbname)
        else:
            run_mgtool (tool, args.name, dbname)

# Let's go on, now with vizGrimoire

def install_vizgrimoirer (libdir, vizgrimoirer_pkgdir):
    """Install the appropriate vizgrimorer R package in a specific location

    - libdir: directory to install R libraries
    - vizgrimoirer_pkgdir: directory with the source code for the
        VizGrimoireR R package

    Installing the package is to ensure it is properly installed,
    even if it is not available from the standard R librdirs,
    or the version there is not the right one.

    """
    try:
        os.makedirs(libdir)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(libdir):
            pass
        else: 
            raise
    env = os.environ.copy()
    env ["R_LIBS"] = libdir
    call (["R", "CMD", "INSTALL", vizgrimoirer_pkgdir], env=env)

install_vizgrimoirer (rConf["libdir"], rConf["vgrpkg"])

# Run unique identities stuff
call ([rConf["unifypeople"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd, "-i", "no"])
call ([rConf["ds2id"],
       "--data-source=its",
       "--db-name-ds=" + dbPrefix + "_" + "bicho",
       "--db-name-ids=" + dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd])

# Run affiliation stuff
call ([rConf["domains"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd])

# Create the JSON data directory for the browser
# R scripts will write JSON files into it
try:
    os.makedirs(JSONdir)
except OSError as e:
    if e.errno == errno.EEXIST and os.path.isdir(JSONdir):
        pass
    else: 
        raise

# Run the SCM (git) analysis script (ensure installed vizgrimoirer package
# is in R lib path)
os.environ["R_LIBS"] = rConf["libdir"] + ":" + os.environ.get("R_LIBS", "")
scm_call = [rConf["scm-analysis"], "-d", dbPrefix + "_" + "cvsanaly",
       "-u", args.user, "-p", args.passwd,
       "-i", dbPrefix + "_" + "cvsanaly", "--granularity", "weeks",
       "--destination", JSONdir]
if not args.verbose:
    print " ".join (scm_call)
call (scm_call)

# Run the ITS (tickets) analysis script (ensure installed vizgrimoirer package
# is in R lib path)
os.environ["R_LIBS"] = rConf["libdir"] + ":" + os.environ.get("R_LIBS", "")
its_call = [rConf["its-analysis"], "-d", dbPrefix + "_" + "bicho",
       "-u", args.user, "-p", args.passwd,
       "-i", dbPrefix + "_" + "cvsanaly", "--granularity", "weeks",
       "--destination", JSONdir]
if not args.verbose:
    print " ".join (its_call)
call (its_call)

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
             "browser/favicon.ico"]
# Files specific to this GitHub example:
ghBrowserfiles = ["index.html",
                  "navbar.html", "footer.html", "refcard.html",
                  "project-card.html",
                  "viz_cfg.json", "custom.css"]
# Files specific to this GitHub example that must go in data/json:
ghJSONfiles = ["config.json"]

for file in vgjsFiles:
    shutil.copy(args.vgdir + "/VizGrimoireJS/" + file, dashboarddir)
for file in ghBrowserfiles:
    shutil.copy(args.vgdir + "/VizGrimoireR/examples/github/" + file,
                dashboarddir)
for file in ghJSONfiles:
    shutil.copy(args.vgdir + "/VizGrimoireR/examples/github/" + file, JSONdir)

# Note: missing files:
# index.htmo, config.json

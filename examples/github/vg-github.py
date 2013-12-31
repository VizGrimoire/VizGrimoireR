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
# Simple script to retrieve data from GitHub repositories about a project,
# or all the projects owned by a user.
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

rConf = {}
args = None
dbPrefix = ""
dir = ""
dashboard_dir = ""
JSONdir = ""

def prepare_db (tool, dbname):
    """Prepare MetricsGrimoire database

    tool: cvsanaly | bicho
    dbname: name of the database

    Prepares (and deletes, if args.removedb was specified) the database
    for a MetricsGrimoire tool.
    This is usually run once per tool, just before the calls to run the tools
    """

    # Open database connection and get a cursor
    con = MySQLdb.connect(host='localhost', user=args.user, passwd=args.passwd) 
    cursor = con.cursor()
    # Create database and remove it in advance, if needed
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

    - tool: cvsanaly | bicho
    - project: GitHub project, such as VizGrimoire/VizGrimoireR
    - dbname: name of the database

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

def run_mgtools (tools, projects, dbprefix):
    """Run MetricsGrimoire tools

    - tools: [cvsanaly, bicho, ...] (list)
    - project: GitHub project, such as VizGrimoire/VizGrimoireR
    - dbname: name of the database

    Run the specified MetricsGRimoire tools, preparing their
    corresponding databases if needed

    """

    for tool in tools:
        # Prepare databases
        dbname = dbprefix + "_" + tool
        prepare_db (tool, dbname)
        # Run tools
        for project in projects:
            run_mgtool (tool, project, dbname)


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


def unique_ids (dbprefix):
    """Run unique identities stuff

    - dbprefix: prefix for the databases

    """

    call ([rConf["unifypeople"], "-d", dbprefix + "_" + "cvsanaly",
           "-u", args.user, "-p", args.passwd, "-i", "no"])
    call ([rConf["ds2id"],
           "--data-source=its",
           "--db-name-ds=" + dbprefix + "_" + "bicho",
           "--db-name-ids=" + dbprefix + "_" + "cvsanaly",
           "-u", args.user, "-p", args.passwd])

def affiliation (dbprefix):
    """Run affiliation stuff

    - dbprefix: prefix for the databases

    """

    call ([rConf["domains"], "-d", dbprefix + "_" + "cvsanaly",
           "-u", args.user, "-p", args.passwd])



def run_analysis (scripts, base_dbs, id_dbs, outdir):
    """Run analysis scripts

    - scripts: scripts to run (list)
    - base_dbs: base database for each script (list)
    - id_dbs: identities database for each script (list)
    - outdir: directory to write output (JSON) files

    The vizgrimoirer R package has to be installed in the R path
    (run install_vizgrimoirer in case of doubt)

    """

    # Create the JSON data directory for the scripts to write to
    try:
        os.makedirs(outdir)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(outdir):
            pass
        else: 
            raise
    # Run the analysis scripts
    os.environ["R_LIBS"] = rConf["libdir"] + ":" + os.environ.get("R_LIBS", "")
    for script, base_db, id_db in zip (scripts, base_dbs, id_dbs):
        call_list = [script, "-d", base_db,
                     "-u", args.user, "-p", args.passwd,
                     "-i", id_db,
                     "--granularity", "weeks",
                     "--destination", outdir]
        if args.verbose:
            print " ".join (call_list)
        call (call_list)


def produce_dashboard (vizgrimoirejs_dir, example_dir,
                       dashboard_dir, json_dir):
    """Produce an HTML dashboard for the JSON files

    - vizgrimoirejs_dir: dir with the source for VizGrimoireJS 
    - example_dir: dir with the source specific for the example 
    - dashboard_dir: dir to copy dashboard files to
    - json_dir: dir for json files

    Produce an HTML dashboard for the JSON files generated by the
    analysis scripts.

    """

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
        shutil.copy(vizgrimoirejs_dir + file, dashboard_dir)
    for file in ghBrowserfiles:
        shutil.copy(example_dir + file, dashboard_dir)
    for file in ghJSONfiles:
        shutil.copy(example_dir + file, json_dir)


if __name__ == "__main__":

    def parse_args ():
        """Parse command line arguments"""

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
        return (args)

    args = parse_args()
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
    dashboard_dir = dir + "/dashboard"
    # JSON directory for browser
    JSONdir = dashboard_dir + "/data/json"

    # Configure R paths
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
                 "/VizGrimoireUtils/identities/domains_analysis.py"
             }
    # Now, if there is no --nomg flag, run MetricsGrimoire tools
    # If it is for a github user, get all the projects under the user name,
    # and run tools on each of them.
    # If it is for a single project, just run the tools on it
    if not args.nomg:
        if args.isuser:
            repos = find_repos (args.name)
        else:
            repos = [args.name]
        run_mgtools (["cvsanaly", "bicho"], repos, dbPrefix)

    # Run unique_ids and affiliation stuff
    unique_ids (dbPrefix)
    affiliation (dbPrefix)

    # Install vizgrimoire R package, just in case
    install_vizgrimoirer (rConf["libdir"], rConf["vgrpkg"])


    run_analysis ([rConf["scm-analysis"], rConf["its-analysis"]],
                  [dbPrefix + "_" + "cvsanaly", dbPrefix + "_" + "bicho"],
                  [dbPrefix + "_" + "cvsanaly", dbPrefix + "_" + "cvsanaly"],
                  JSONdir)

    produce_dashboard (vizgrimoirejs_dir = args.vgdir + "/VizGrimoireJS/",
                       example_dir = args.vgdir + "/VizGrimoireR/examples/github/",
                       dashboard_dir = dashboard_dir, json_dir = JSONdir)

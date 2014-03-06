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
#       Luis Cañas-Díaz <lcanas@bitergia.com>
#       Daniel Izquierdo Cortázar <dizquierdo@bitergia.com>
#       Alvaro del Castillo San Felix <acs@bitergia.com>
#
# launch.py
#
# This script executes R scripts in order to generate the
# JSON files

import os
import sys
import time

from optparse import OptionParser
from ConfigParser import SafeConfigParser

# conf variables from file(see read_main_conf)
options = {}

def get_options():
    parser = OptionParser(usage='Usage: %prog [options]',
                          description='Executes the R scripts which analyze the information stored in the relational data bases and produce JSON files',
                          version='0.1')

    parser.add_option('-f', dest='config_file',
                      help='File path with the configuration for the R scripts',
                      default=None)
    parser.add_option('-g', '--debug', action='store_true', dest='debug',
                        help='Enable debug mode', default=False)
    parser.add_option('-s', dest='section',
                      help='Section to be done: scm, its, mls, scr, irc, mediawiki, people',
                      default=None)
    parser.add_option('--python', dest='python', action="store_true",
                      help='Use python script for getting metrics.')

    (ops, args) = parser.parse_args()

    if ops.config_file is None:
        parser.print_help()
        print("Configuration file is required")
        sys.exit(1)
    return ops

def read_main_conf(config_file):
    parser = SafeConfigParser()
    fd = open(config_file, 'r')
    parser.readfp(fd)
    fd.close()

    sec = parser.sections()
    # we'll read "generic" for db information and "r" for start_date
    for s in sec:
        if not((s == "generic") or (s == "r")):
            continue
        options[s] = {}
        opti = parser.options(s)
        for o in opti:
            options[s][o] = parser.get(s, o)
    return options


def check_configuration():
    if 'db_bicho' in options['generic']:
        try:
            'bicho_backend' in options['generic'] == True
        except:
            print "Configuration error: Configuration section for [generic] with 'backend_bicho'\
 variable expected"
            sys.exit(-1)

def get_vars():
    v = {}
    v = options['generic']
    v.update(options['r'])
    # Fixed locations
    v['r_libs'] = '../../r-lib'
    v['python_libs'] = '../vizgrimoire'
    v['json_dir'] = '../../../json'

    # if end_date is not present or is empty we set up today's date
    if not ('end_date' in v):
        v['end_date'] = time.strftime('%Y-%m-%d')

    # FIXME this should be included in the main log file
    v['log_file'] = 'run-analysis.log'
    if (v['db_password'] == ""):
        v['db_password'] = "''"
    return v

def get_analysis_cmd(v, script, db):
    if (not get_options().python):
        cmd = "LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s " % \
            (v['r_libs'], v['reports'], db , v['db_user'], v['db_password'])
    else:
        script = script.replace(".R",".py")
        print(script)
        cmd = "PYTHONPATH=%s LANG= R_LIBS=%s ./%s -r %s -d %s -u %s -p %s " % \
            (v['python_libs'], v['r_libs'], script, v['reports'], db , v['db_user'], v['db_password'])
    cmd += "-i %s -s %s -e %s -o %s -g %s " % \
        (v['db_identities'], v['start_date'], v['end_date'], v['json_dir'], v['period'])
    if script == "its-analysis.R" or script == "its-analysis.py":
        cmd += "-t %s " % (v['bicho_backend'])
    if v.has_key('people_number'):
        cmd += "--npeople %s " %  (v['people_number'])
    else:
        cmd += "--npeople 10 " # default value is 10
    if (not get_options().python):
        cmd += " < %s >> %s 2>&1" % (script, v['log_file'])
    else:
        cmd += " >> %s 2>&1" % (v['log_file'])


    if (get_options().debug): print(cmd)
    return (cmd)

def execute_scm_script(env):
    if not 'db_cvsanaly' in env:
        print("SCM analysis disabled")
        return
    print("Starting SCM analysis ..")
    cmd = get_analysis_cmd(env, "scm-analysis.R", env['db_cvsanaly'])
    os.system(cmd)
    print("SCM analysis finished")

def execute_people_script(env):
    # TODO: right now people script uses cvsanaly db 
    if not 'db_cvsanaly' in env:
        print("People analysis disabled")
        return
    print("Starting People analysis ..")
    cmd = get_analysis_cmd(env, "people-analysis.R", env['db_cvsanaly'])
    os.system(cmd)
    print("People analysis finished")

def execute_people_experimental_script(env):
    # this proc doesn't use the get_analysis_cmd function
    print("Starting People EXPERIMENTAL analysis ..")
    cmd = "PYTHONPATH=%s ./%s -f %s 2>&1 %s" % (env['python_libs'], 'people-analysis-experimental.py', opt.config_file, env['log_file'])
    print(cmd)
    #use subprocess or popen instead of os which is very old fashion
    os.system(cmd)
    print("People EXPERIMENTAL analysis finished")

def execute_its_script(env):
    if not 'db_bicho' in env:
        print("ITS analysis disabled")
        return
    print("Starting ITS analysis  ..")
    cmd = get_analysis_cmd(env, "its-analysis.R", env['db_bicho'])
    os.system(cmd)
    print("ITS analysis finished")

def execute_mls_script(env):
    if not 'db_mlstats' in env:
        print("MLS analysis disabled")
        return
    print("Starting MLS analysis  ..")
    cmd = get_analysis_cmd(env, "mls-analysis.R", env['db_mlstats'])
    os.system(cmd)
    print("MLS analysis finished")

def execute_scr_script(env):
    if not 'db_gerrit' in env:
        print("SRC analysis disabled")
        return
    print("Starting SCR analysis  ..")
    cmd = get_analysis_cmd(env, "scr-analysis.R", env['db_gerrit'])
    os.system(cmd)
    print("SCR analysis finished")

def execute_irc_script(env):
    if not 'db_irc' in env:
        print("IRC analysis disabled")
        return
    print("Starting IRC analysis  ..")
    cmd = get_analysis_cmd(env, "irc-analysis.R", env['db_irc'])
    os.system(cmd)
    print("IRC analysis finished")


def execute_mediawiki_script(env):
    if not 'db_mediawiki' in env:
        print("mediawiki analysis disabled")
        return
    print("Starting MediaWiki analysis  ..")
    cmd = get_analysis_cmd(env, "mediawiki-analysis.R", env['db_mediawiki'])
    os.system(cmd)
    print("MediaWiki analysis finished")

tasks_section = {
    'scm':execute_scm_script,
    'people':execute_people_script,
    'people_experimental':execute_people_experimental_script,
    'its':execute_its_script,
    'mls':execute_mls_script,
    'scr':execute_scr_script,
    'mediawiki':execute_mediawiki_script,
    'irc': execute_irc_script,
}
#tasks_order = ['scm','people','its','mls','scr','mediawiki','irc']
tasks_order = ['people_experimental']



if __name__ == '__main__':
    opt = get_options()
    read_main_conf(opt.config_file)
    check_configuration()
    env = get_vars()

    if opt.section is not None:
        tasks_section[opt.section](env)
    else:
        for section in tasks_order:
            tasks_section[section](env)

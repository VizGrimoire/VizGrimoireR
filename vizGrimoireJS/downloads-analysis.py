#!/usr/bin/env python

# Copyright (C) 2014 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# This file is a part of the vizGrimoire package
#
## Authors:
## Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>
#
#
# Example of use: PYTHONPATH=../vizgrimoire:../vizgrimoire/analysis LANG= ./downloads-analysis.py 
#                            -d testing -u root -p "" -s 2014-01-19 -e 2014-02-21 -i fake -o "./data/"

import logging
import sys
import GrimoireUtils, GrimoireSQL
from GrimoireUtils import dataFrame2Dict, createJSON, completePeriodIds, read_options, getPeriod
from optparse import OptionParser
from Downloads import *


if __name__ == '__main__':

    opts = read_options()
    period = getPeriod(opts.granularity)
    nperiod = getPeriod(opts.granularity, True)
    destdir = opts.destdir

    startdate = "'"+opts.startdate+"'"
    enddate = "'"+opts.enddate+"'"

    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    logging.info("Starting Downloads analysis")
   
    GrimoireSQL.SetDBChannel (database=opts.dbname, user=opts.dbuser, password=opts.dbpassword)
    
    downloads = EvolDownloads(period, startdate, enddate)
    packages = EvolPackages(period, startdate, enddate)
    protocols = EvolProtocols(period, startdate, enddate)
    ips = EvolIPs(period, startdate, enddate)
    evol = dict(downloads.items() + packages.items() + protocols.items() + ips.items())
    evol = completePeriodIds(evol)
    createJSON (evol, destdir+"/downs-evolutionary.json")

    downloads = AggDownloads(period, startdate, enddate)
    packages = AggPackages(period, startdate, enddate)
    protocols = AggProtocols(period, startdate, enddate)
    ips = AggIPs(period, startdate, enddate)
    agg = dict(downloads.items() + packages.items() + protocols.items() + ips.items())
    createJSON(agg, destdir+"/downs-static.json")

    top20ips = TopIPs(startdate, enddate, 20)
    createJSON(top20ips, destdir+"downs-top-ips.json")
    top20packages = TopPackages(startdate, enddate, 20)
    createJSON(top20packages, destdir+"downs-top-packages.json")


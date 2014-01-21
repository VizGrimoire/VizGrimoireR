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
# This file is a part of the vizGrimoire.R package
#
# Authors:
#     Alvaro del Castillo <acs@bitergia.com>

import GrimoireUtils

def StaticNumSentIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT count(message) as sent, \
              DATE_FORMAT (min(date), '%Y-%m-%d') as first_date, \
              DATE_FORMAT (max(date), '%Y-%m-%d') as last_date "
    tables = " FROM irclog "
    filters = "WHERE date >=" + startdate + " and date < " + enddate
    q = fields + tables + filters
    return(GrimoireUtils.ExecuteQuery(q))

def StaticNumSendersIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT count(distinct(nick)) as senders"
    tables = " FROM irclog "
    filters = "WHERE date >=" + startdate + " and date < " + enddate
    q = fields + tables + filters
    return(GrimoireUtils.ExecuteQuery(q))

def StaticNumRepositoriesIRC (period, startdate, enddate, identities_db=None, type_analysis=[]):
    fields = "SELECT COUNT(DISTINCT(channel_id)) AS repositories "
    tables = "FROM irclog "
    filters = "WHERE date >=" + startdate + " AND date < " + enddate
    q = fields + tables + filters
    return(GrimoireUtils.ExecuteQuery(q))


def GetStaticDataIRC(period, startdate, enddate, idb = None, type_analysis=[]):
    agg_data = "GetStaticDataIRC"

    sent = StaticNumSentIRC(period, startdate, enddate, idb, type_analysis)
    senders = StaticNumSendersIRC(period, startdate, enddate, idb, type_analysis)
    repositories = StaticNumRepositoriesIRC(period, startdate, enddate, idb, type_analysis)
    agg_data = dict(sent.items() + senders.items() + repositories.items())

    return (agg_data)
# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2014 Bitergia
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
# Authors:
#         Santiago Dueñas <sduenas@bitergia.com>
#

"""Misc functions for testing the library"""

from csv import DictReader

from vizgrimoire.GrimoireSQL import SetDBChannel


def set_db_channel(user='root', password='', database=None,
                   host="127.0.0.1", port=3306, group=None):
    SetDBChannel(user, password, database, host, port, group)


def read_dataset(filepath, fieldnames, delimiter):
    data = {field : [] for field in fieldnames}

    with open(filepath, 'r') as f:
        cvs = DictReader(f, fieldnames=fieldnames,
                          delimiter=delimiter)
        for line in cvs:
            for field, value in line.items():
                data[field].append(value)
    return data

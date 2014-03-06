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
#         Luís Cañas-Díaz <lcanas@bitergia.com>
#         Santiago Dueñas <sduenas@bitergia.com>
#

"""Tests for IRC data analysis"""

import sys
import unittest

if not '..' in sys.path:
    sys.path.insert(0, '../..')

from vizgrimoire.IRC import *
from utils import set_db_channel


DB_IRC_TEST = 'jenkins_irc_vizr_1783'
DB_IDENTITIES_TEST = 'jenkins_scm_vizr_1783'


class TestIRCtatic(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_IRC_TEST)

    def test_static_num_sent_week(self):
        result = StaticNumSentIRC('week', "'2013-01-01'", "'2013-01-08'", None, [])
        self.assertEqual(2168, result['sent'])

        result = StaticNumSentIRC('week', "'2012-01-01'", "'2012-01-08'", None, [])
        self.assertEqual(0, result['sent'])

    def test_static_num_sent_month(self):
        result = StaticNumSentIRC('month', "'2013-01-01'", "'2013-02-01'", None, [])
        self.assertEqual(9300, result['sent'])

        result = StaticNumSentIRC('month', "'2012-01-01'", "'2012-02-01'", None, [])
        self.assertEqual(0, result['sent'])

    def test_static_num_senders_week(self):
        result = StaticNumSendersIRC('week', "'2013-01-01'", "'2013-01-08'", None, [])
        self.assertEqual(14, result['senders'])

        result = StaticNumSendersIRC('week', "'2012-01-01'", "'2012-01-08'", None, [])
        self.assertEqual(0, result['senders'])

    def test_static_num_senders_month(self):
        result = StaticNumSendersIRC('month', "'2013-01-01'", "'2013-02-01'", None, [])
        self.assertEqual(28, result['senders'])

        result = StaticNumSendersIRC('month', "'2012-01-01'", "'2012-02-01'", None, [])
        self.assertEqual(0, result['senders'])

    def test_static_num_people():
        result = GetPeopleIRC()
        self.assertEqual(0, result['members'])


if __name__ == "__main__":
    unittest.main()

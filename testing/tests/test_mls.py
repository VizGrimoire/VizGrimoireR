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
#         Daniel Izquierdo <dizquierdo@bitergia.com>
#         Santiago Dueñas <sduenas@bitergia.com>
#

"""Tests for MLS data analysis"""

import sys
import unittest

if not '..' in sys.path:
    sys.path.insert(0, '../..')

from vizgrimoire.MLS import *
from utils import set_db_channel


DB_MLS_TEST = 'jenkins_mls_vizr_1783'
DB_IDENTITIES_TEST = 'jenkins_scm_vizr_1783'


class TestMLSEvolutionary(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_MLS_TEST)

    def test_evol_emails_sent_week(self):
        results = EvolEmailsSent('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(50, len(results['sent']))

    def test_evol_emails_sent_month(self):
        results = EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['sent']))

    def test_evol_emails_sent_company(self):
        results = EvolEmailsSent('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(12, len(results['sent']))

    def test_evol_email_senders_week(self):
        results = EvolMLSSenders('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(50, len(results['senders']))

    def test_evol_email_senders_month(self):
        results = EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['senders']))

    def test_evol_email_senders_company(self):
        results = EvolMLSSenders('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Rackspace'"])
        self.assertEqual(11, len(results['senders']))

    def test_evol_senders_response_week(self):
        results = EvolMLSSendersResponse('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(50, len(results['senders_response']))

    def test_evol_senders_response_month(self):
        results = EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(12, len(results['senders_response']))

    def test_evol_senders_response_company(self):
        results = EvolMLSSendersResponse('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Rackspace'"])
        self.assertEqual(11, len(results['senders_response']))

    def test_evol_senders_init_week(self):
        results = EvolMLSSendersInit('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(50, len(results['senders_init']))

    def test_evol_senders_init_month(self):
        results = EvolMLSSendersInit('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(12, len(results['senders_init']))

    def test_evol_senders_init_company(self):
        results = EvolMLSSendersInit('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Rackspace'"])
        self.assertEqual(7, len(results['senders_init']))

    def test_evol_threads_week(self):
        results = EvolThreads('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(50, len(results['threads']))

    def test_evol_threads_month(self):
        results = EvolThreads('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['threads']))

    def test_evol_threads_company(self):
        results = EvolThreads('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Rackspace'"])
        self.assertEqual(11, len(results['threads']))

    def test_evol_companies_month(self):
        results = EvolMLSCompanies('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST)
        self.assertEqual(12, len(results['companies']))


class TestMLSStatic(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_MLS_TEST, password='root')

    def test_agg_companies_month(self):
        result = AggMLSCompanies('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST)
        self.assertEqual(24, result['companies'])

    def test_static_num_active_people_7(self):
        result = GetActivePeopleMLS(7, "'2013-01-01'")
        self.assertEqual(1466, len(result))
        result = GetActivePeopleMLS(30, "'2013-01-01'")
        self.assertEqual(1493, len(result))
        result = GetActivePeopleMLS(180, "'2013-01-01'")
        self.assertEqual(1659, len(result))
        result = GetActivePeopleMLS(365, "'2013-01-01'")
        self.assertEqual(1718, len(result))

if __name__ == "__main__":
    unittest.main()

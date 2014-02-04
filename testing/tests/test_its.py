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
#         Luís Cañas-Díaz <lcanas@bitergia.com>
#         Santiago Dueñas <sduenas@bitergia.com>
#

"""Tests for ITS data analysis"""

import sys
import unittest

if not '..' in sys.path:
    sys.path.insert(0, '../..')

from vizgrimoire.ITS import *
from utils import set_db_channel


DB_ITS_TEST = 'jenkins_its_vizr_1783'
DB_IDENTITIES_TEST = 'jenkins_scm_vizr_1783'
CLOSED_COND = " (new_value='Fix Committed') "


class TestITSEvol(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_ITS_TEST)

    def test_evol_issues_opened_week(self):
        results = EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(54, len(results['opened']))

    def test_evol_issues_opened_company_week(self):
        results = EvolIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(44, len(results['opened']))

    def test_evol_issues_opened_month(self):
        results = EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['opened']))

    def test_evol_issues_opened_company_month(self):
        results = EvolIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(12, len(results['opened']))

    def test_evol_issues_openers_week(self):
        results = EvolIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", None, [], None)
        self.assertEqual(54, len(results['openers']))

    def test_evol_issues_openers_company_week(self):
        results = EvolIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], None)
        self.assertEqual(44, len(results['openers']))

    def test_evol_issues_openers_month(self):
        results = EvolIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", None, [], None)
        self.assertEqual(12, len(results['openers']))

    def test_evol_issues_openers_company_month(self):
        results = EvolIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], None)
        self.assertEqual(12, len(results['openers']))

    def test_evol_issues_closed_week(self):
        results = EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(52, len(results['closed']))

    def test_evol_issues_closed_repository_week(self):
        results = EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"], CLOSED_COND)
        self.assertEqual(52, len(results['closed']))

    def test_evol_issues_closed_company_week(self):
        results = EvolIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], CLOSED_COND)
        self.assertEqual(4, len(results['closed']))

    def test_evol_issues_closed_month(self):
        results = EvolIssuesClosed('month', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(12, len(results['closed']))

    def test_evol_issues_closers_week(self):
        results = EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(52, len(results['closers']))

    def test_evol_issues_closers_repository_week(self):
        results = EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"], CLOSED_COND)
        self.assertEqual(52, len(results['closers']))

    def test_evol_issues_closers_company_week(self):
        results = EvolIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], CLOSED_COND)
        self.assertEqual(4, len(results['closers']))

    def test_evol_issues_closers_month(self):
        results = EvolIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(12, len(results['closers']))

    def test_evol_issues_changed_week(self):
        results = EvolIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(54, len(results['changed']))

    def test_evol_issues_changed_repository_week(self):
        results = EvolIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"])
        self.assertEqual(54, len(results['changed']))

    def test_evol_issues_changed_company_week(self):
        results = EvolIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(48, len(results['changed']))

    def test_evol_issues_changed_month(self):
        results = EvolIssuesChanged('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['changed']))

    def test_evol_issues_changers_week(self):
        results = EvolIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(54, len(results['changers']))

    def test_evol_issues_changers_repository_week(self):
        results = EvolIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"])
        self.assertEqual(54, len(results['changers']))

    def test_evol_issues_changers_company_week(self):
        results = EvolIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(48, len(results['changers']))

    def test_evol_issues_changers_month(self):
        results = EvolIssuesChangers('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['changers']))

    def test_evol_issues_repositories_week(self):
        results = EvolIssuesRepositories('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(54, len(results['trackers']))

    def test_evol_issues_repositories_month(self):
        results = EvolIssuesRepositories('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(12, len(results['trackers']))

    def test_evol_issues_companies_month(self):
        results = EvolIssuesCompanies('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST)
        self.assertEqual(12, len(results['companies']))


class TestITSStatic(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_ITS_TEST)

    def test_static_agg_issues_opened_week(self):
        result = AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(7809, result['opened'])

    def test_static_agg_issues_opened_repository_week(self):
        result = AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"])
        self.assertEqual(2416, result['opened'])

    def test_static_agg_issues_opened_company_week(self):
        result = AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(151, result['opened'])

    def test_static_agg_issues_opened_domain_week(self):
        result = AggIssuesOpened('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['domain', "'redhat'"])
        self.assertEqual(162, result['opened'])

    def test_static_agg_issues_opened_month(self):
        result = AggIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(7809, result['opened'])

    def test_static_agg_issues_opened_company_month(self):
        result = AggIssuesOpened('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(151, result['opened'])

    def test_static_agg_issues_openers_week(self):
        result = AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", None, [], None)
        self.assertEqual(941, result['openers'])

    def test_static_agg_issues_openers_repository_week(self):
        result = AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"], None)
        self.assertEqual(523, result['openers'])

    def test_static_agg_issues_openers_company_week(self):
        result = AggIssuesOpeners('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], None)
        self.assertEqual(14, result['openers'])

    def test_static_agg_issues_openers_month(self):
        result = AggIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", None, [], None)
        self.assertEqual(941, result['openers'])

    def test_static_agg_issues_openers_company_month(self):
        result = AggIssuesOpeners('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], None)
        self.assertEqual(14, result['openers'])

    def test_static_agg_issues_closed_week(self):
        result = AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(4716, result['closed'])

    def test_static_agg_issues_closed_repository_week(self):
        result = AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"], CLOSED_COND)
        self.assertEqual(1653, result['closed'])

    def test_static_agg_issues_closed_company_week(self):
        result = AggIssuesClosed('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], CLOSED_COND)
        self.assertEqual(5, result['closed'])

    def test_static_agg_issues_closed_month(self):
        result = AggIssuesClosed('month', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(4716, result['closed'])

    def test_static_agg_issues_closers_week(self):
        result = AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(172, result['closers'])

    def test_static_agg_issues_closers_repository_week(self):
        result = AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"], CLOSED_COND)
        self.assertEqual(77, result['closers'])

    def test_static_agg_issues_closers_company_week(self):
        result = AggIssuesClosers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"], CLOSED_COND)
        self.assertEqual(4, result['closers'])

    def test_static_agg_issues_closers_month(self):
        result = AggIssuesClosers('month', "'2012-01-01'", "'2013-01-01'", None, [], CLOSED_COND)
        self.assertEqual(172, result['closers'])

    def test_static_agg_issues_changed_week(self):
        result = AggIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(9726, result['changed'])

    def test_static_agg_issues_changed_repository_week(self):
        result = AggIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"])
        self.assertEqual(3134, result['changed'])

    def test_static_agg_issues_changed_company_week(self):
        result = AggIssuesChanged('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(242, result['changed'])

    def test_static_agg_issues_changed_month(self):
        result = AggIssuesChanged('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(9726, result['changed'])

    def test_static_agg_issues_changers_week(self):
        result = AggIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(1334, result['changers'])

    def test_static_agg_issues_changers_repository_week(self):
        result = AggIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['repository', "'https://bugs.launchpad.net/nova'"])
        self.assertEqual(809, result['changers'])

    def test_static_agg_issues_changers_company_week(self):
        result = AggIssuesChangers('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, ['company', "'Red Hat'"])
        self.assertEqual(15, result['changers'])

    def test_static_agg_issues_changers_month(self):
        result = AggIssuesChangers('month', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(1334, result['changers'])

    def test_static_agg_issues_companies_month(self):
        result = AggIssuesCompanies('month', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST)
        self.assertEqual(35, result['companies'])


class TestITSLists(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_ITS_TEST)

    def test_repos_name(self):
        results = GetReposNameITS("'2012-01-01'", "'2013-01-01'")
        self.assertEqual(34, len(results['name']))

    def test_companies_name(self):
        results = GetCompaniesNameITS("'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, CLOSED_COND, [])
        self.assertEqual(23, len(results['name']))


if __name__ == "__main__":
    unittest.main()

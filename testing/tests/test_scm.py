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

"""Tests for SCM data analysis"""

import sys
import unittest

if not '..' in sys.path:
    sys.path.insert(0, '../..')

from decimal import Decimal

from vizgrimoire.SCM import *
from utils import set_db_channel

DB_SCM_TEST = 'jenkins_scm_vizr_1783'
DB_IDENTITIES_TEST = 'jenkins_scm_vizr_1783'


class TestSCMQueries(unittest.TestCase):

    def test_SQLRepositoriesFrom(self):
        self.assertEqual(" , repositories r", GetSQLRepositoriesFrom())


class TestSCMEvolutionary(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_SCM_TEST)

    def test_evol_commits(self):
        results = EvolCommits('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(54, len(results['commits']))

    def test_evol_authors(self):
        results = EvolAuthors('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['authors']))

    def test_evol_committers(self):
        results = EvolCommitters('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['committers']))

    def test_evol_files(self):
        results = EvolFiles('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['files']))

    def test_evol_lines(self):
        results = EvolLines('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['added_lines']))

    def test_evol_branches(self):
        results = EvolBranches('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['branches']))

    def test_evol_repositories(self):
        results = EvolRepositories('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['repositories']))

    def test_evol_actions(self):
        results = EvolActions('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['actions']))

    def test_evol_avg_commits_authors(self):
        results = EvolAvgCommitsAuthor('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['avg_commits_author']))

    def test_evol_avg_files_authors(self):
        results = EvolAvgFilesAuthor('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(54, len(results['avg_files_author']))


class TestSCMStatic(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_SCM_TEST)

    def test_static_num_commits(self):
        result = StaticNumCommits('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(13725, result['commits'])

    def test_static_num_authors(self):
        result = StaticNumAuthors('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(564, result['authors'])

    def test_static_num_committers(self):
        result = StaticNumCommitters('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(536, result['committers'])

    def test_static_num_files(self):
        result = StaticNumFiles('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(14518, result['files'])

    def test_static_num_branches(self):
        result = StaticNumBranches('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(5, result['branches'])

    def test_static_num_repositories(self):
        result = StaticNumRepositories('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(45, result['repositories'])

    def test_static_num_actions(self):
        result = StaticNumActions('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(59781, result['actions'])

    def test_static_avg_commits_period(self):
        result = StaticAvgCommitsPeriod('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(Decimal('263.9423'), result['avg_commits_week'])

    def test_static_avg_files_period(self):
        result = StaticAvgFilesPeriod('week', "'2012-01-01'", "'2013-01-01'", None, [])
        self.assertEqual(Decimal('279.1923'), result['avg_files_week'])

    def test_static_avg_commits_author(self):
        result = StaticAvgCommitsAuthor('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(Decimal('24.3351'), result['avg_commits_author'])

    def test_static_avg_author_period(self):
        result = StaticAvgAuthorPeriod('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(Decimal('10.8462'), result['avg_authors_week'])

    def test_static_avg_committer_period(self):
        result = StaticAvgCommitterPeriod('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        # FIXME: StaticAvgCommitterPeriod returns 'avg_authors_week'
        # instead of 'avg_committers_week'. Fix it in SCM.py and SCM.R 
        # files
        self.assertEqual(Decimal('10.3077'), result['avg_authors_week'])

    def test_static_avg_files_author(self):
        result = StaticAvgFilesAuthor('week', "'2012-01-01'", "'2013-01-01'", DB_IDENTITIES_TEST, [])
        self.assertEqual(Decimal('25.7411'), result['avg_files_author'])
        
    def test_static_num_active_people_7(self):
        result = GetActivePeopleSCM(7, "'2013-01-01'")
        self.assertEqual(709, len(result))
        result = GetActivePeopleSCM(30, "'2013-01-01'")
        self.assertEqual(728, len(result))
        result = GetActivePeopleSCM(180, "'2013-01-01'")
        self.assertEqual(874, len(result))
        result = GetActivePeopleSCM(365, "'2013-01-01'")
        self.assertEqual(969, len(result))

    def test_static_num_community_members(self):
        result = GetCommunityMembers()
        self.assertEqual(3605, len(result))


if __name__ == "__main__":
    unittest.main()

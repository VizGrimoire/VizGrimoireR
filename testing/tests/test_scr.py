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

"""Tests for SCR data analysis"""

import sys
import unittest

if not '..' in sys.path:
    sys.path.insert(0, '../..')

from vizgrimoire.SCR import *
from utils import set_db_channel


DB_SCR_TEST = 'jenkins_scr_vizr_1783'
DB_IDENTITIES_TEST = 'jenkins_scm_vizr_1783'


class TestSCREvol(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_SCR_TEST)

    def test_evol_reviews_submitted(self):
        results = EvolReviewsSubmitted('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['submitted']))

    def test_evol_reviews_opened(self):
        results = EvolReviewsOpened('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(4, len(results['opened']))

    def test_evol_reviews_new(self):
        results = EvolReviewsNew('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(2, len(results['new']))

    def test_evol_reviews_new_changes(self):
        results = EvolReviewsNewChanges('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(0, len(results['new_changes']))

    def test_evol_reviews_in_progress(self):
        results = EvolReviewsInProgress('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(0, len(results['inprogress']))

    def test_evol_reviews_closed(self):
        results = EvolReviewsClosed('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['closed']))

    def test_evol_reviews_merged(self):
        results = EvolReviewsMerged('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['merged']))

    def test_evol_reviews_merged_changes(self):
        results = EvolReviewsMergedChanges('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(0, len(results['merged_changes']))

    def test_evol_reviews_abandoned(self):
        results = EvolReviewsAbandoned('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(53, len(results['abandoned']))

    def test_evol_reviews_abandoned_changes(self):
        results = EvolReviewsAbandonedChanges('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(0, len(results['abandoned_changes']))

    def test_evol_patches_approved(self):
        results = EvolPatchesApproved('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['approved']))

    def test_evol_patches_verified(self):
        results = EvolPatchesVerified('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['verified']))

    def test_evol_patches_code_review(self):
        results = EvolPatchesCodeReview('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['codereview']))

    def test_evol_patches_sent(self):
        results = EvolPatchesSent('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(53, len(results['sent']))

    def test_evol_waiting_for_reviewer(self):
        results = EvolWaiting4Reviewer('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(2, len(results['WaitingForReviewer']))

    def test_evol_waiting_for_submitted(self):
        results = EvolWaiting4Submitter('week', "'2012-01-01'", "'2013-01-01'", [])
        # FIXME: this function does not return a list
        self.assertEqual(1, results['WaitingForSubmitter'])

    def test_evol_reviewers(self):
        results = EvolReviewers('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(54, len(results['reviewers']))


class TestSCRStatic(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        set_db_channel(database=DB_SCR_TEST)

    def test_static_reviews_submitted(self):
        result = StaticReviewsSubmitted('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(16067, result['submitted'])

    def test_static_reviews_opened(self):
        result = StaticReviewsOpened('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(5, result['opened'])

    def test_static_reviews_new(self):
        result = StaticReviewsNew('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(2, result['new'])

    def test_static_reviews_in_progress(self):
        result = StaticReviewsInProgress('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(0, result['inprogress'])

    def test_static_reviews_closed(self):
        result = StaticReviewsClosed('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(16062, result['closed'])

    def test_static_reviews_merged(self):
        result = StaticReviewsMerged('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(13628, result['merged'])

    def test_static_reviews_abandoned(self):
        result = StaticReviewsAbandoned('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(2434, result['abandoned'])

    def test_static_patches_approved(self):
        result = StaticPatchesApproved('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(13328, result['approved'])

    def test_static_patches_verified(self):
        result = StaticPatchesVerified('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(28218, result['verified'])

    def test_static_patches_code_review(self):
        result = StaticPatchesCodeReview('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(35883, result['codereview'])

    def test_static_patches_sent(self):
        result = StaticPatchesSent('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(11941, result['sent'])

    def test_static_waiting_for_reviewer(self):
        result = StaticWaiting4Reviewer('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(2, result['WaitingForReviewer'])

    def test_static_waiting_for_submitter(self):
        result = StaticWaiting4Submitter('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(1, result['WaitingForSubmitter'])

    def test_static_reviewers(self):
        result = StaticReviewers('week', "'2012-01-01'", "'2013-01-01'", [])
        self.assertEqual(1545, result['reviewers'])


if __name__ == "__main__":
    unittest.main()

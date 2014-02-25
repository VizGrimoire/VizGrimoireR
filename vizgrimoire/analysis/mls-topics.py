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
#
# Authors:
#     Daniel Izquierdo Cortázar <dizquierdo@bitergia.com>

# Mailing lists main topics study

class mls_topics(object):
    # This class contains the analysis of the mailing list from the point
    # of view of threads. The main topics are those with the longest,
    # the most crowded or the thread with the most verbose emails.

    def __init__ (self, date)
        self.date = date
        # Initialize data structure
        self.threads = _init_threads()
        self.crowded = None # the thread with most people participating
        self.longest = None # the thread with the longest queue of emails
        self.verbose = None # the thread with the most verbose emails.

    def _init_threads(self):
        

    def crowded_list (self):
        # Returns the most crowded thread.
        # This is defined as the thread with the highest number of different
        # participants
        if self.crowded == None:
            # variable was not initialize

    def longest_list (self):
        # Returns the longest thread
        if self.longest == None;
            # variable was not initialize

    def verbose_list (self):
        # Returns the most verbose thread (the biggest emails)
        if self.verbose == None:
            # variable was not initialize

    def threads (self):
        # Returns the whole data structure
        if self.threads == None:
            # variable was not initialize
            self.threads = _init_threads()

        return self.threads



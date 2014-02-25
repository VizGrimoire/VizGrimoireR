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
#     Daniel Izquierdo Cortazar <dizquierdo@bitergia.com>

# Mailing lists main topics study

import GrimoireUtils
import GrimoireSQL
from GrimoireSQL import ExecuteQuery

class MLSTopics(object):
    # This class contains the analysis of the mailing list from the point
    # of view of threads. The main topics are those with the longest,
    # the most crowded or the thread with the most verbose emails.

    def __init__ (self, date):
        self.date = date
        self.list_message_id = []
        self.list_is_response_of = []
        self.threads = {}
        self.crowded = None # the thread with most people participating
        self.longest = None # the thread with the longest queue of emails
        self.verbose = None # the thread with the most verbose emails.

        self._init_threads()    
        print self.threads

    def _build_threads (self, message_id):
        sons = []
        messages = []
        print "    * build threads for message_id: " + message_id
        if message_id not in self.list_is_response_of:
            # this a leaf of the tree!
            print "        - Leaf of the tree: message_id = " + message_id
            return []

        else:
            cont = 0
            for msg in self.list_is_response_of:
                #Retrieving all of the sons of a given msg
                if msg == message_id:
                    sons.append(self.list_message_id[cont])
                cont = cont + 1
            print "        - Sons of the message_id: " 
            print sons
            for msg in sons:
                print "            - son: " + msg
                messages.extend([msg])
                messages.extend(self._build_threads(msg))            
                print "            - list of messages: " 
                print messages
               

        return messages          
            

    def _init_threads(self):
        # Returns dictionary of message_id threads. Each key contains a list
        # of emails associated to that thread (not ordered).
       
        # Retrieving all of the messages. 
        query = """
                select message_ID, is_response_of from messages 
                """
        list_messages = ExecuteQuery(query)
        self.list_message_id = list_messages["message_ID"]
        self.list_is_response_of = list_messages["is_response_of"]
        
        messages = {}
        for message_id in self.list_message_id:
            # Looking for messages in the thread
            index = self.list_message_id.index(message_id)
            
            # Only analyzing those whose is_response_of is None, 
            # those are the message 'root' of each thread.
            if self.list_is_response_of[index] is None:
                print "STARTING THE PROCESS FOR A MESSAGE: " + message_id
                messages[message_id] = self._build_threads(message_id)
                print "Final message_id: " + message_id
                print "Final sons: " 
                print messages[message_id]
                print "ENDING THE PROCESS FOR THAT MESSAGE"


        self.threads = messages

    def crowded_list (self):
        # Returns the most crowded thread.
        # This is defined as the thread with the highest number of different
        # participants
        if self.crowded == None:
            # variable was not initialize
            pass

    def longest_list (self):
        # Returns the longest thread
        if self.longest == None:
            # variable was not initialize
            pass

    def verbose_list (self):
        # Returns the most verbose thread (the biggest emails)
        if self.verbose == None:
            # variable was not initialize
            pass

    def threads (self):
        # Returns the whole data structure
        if self.threads == None:
            # variable was not initialize
            pass

        return self.threads



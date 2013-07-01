#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2012 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Authors :
#       Daniel Izquierdo Cortázar <dizquierdo@bitergia.com>
#
# validator.py
#
# This script provides an initial and basic validation of the JSON
# files automatically obtained as output of the execution of the
# VizGrimoireR library

import os
import sys
import json

def check_empty_json_files(json_dir, json_files):
    # If a json file is found empty, file is warned as being empty

    print "The following JSON files are empty: "
    for json_file in json_files:
        json_path = os.path.join(json_dir, json_file)
        fd = open(json_path, "r")
        json_content = json.load(fd)
        if len(json_content) == 0:
            print "    " + json_path
        fd.close()

def check_NA_values(json_dir, json_files):
    # If there is a NA value, that file is marked as a container of NA values

    print "The following JSON files contain NA values: "
    for json_file in json_files:
        NA_found = False
        json_path = os.path.join(json_dir, json_file)
        fd = open(json_path, "r")
        json_content = json.load(fd)
        if len(json_content) > 0:
            if isinstance(json_content, list):
                if "NA" in json_content:
                #print json_content
                #for entry in json_content.iterkeys():
                #    if "NA" in entry:
                #        NA_found = True
                    NA_found = True
            else:
                for value in json_content.iterkeys():
                    if json_content[value] == "NA": 
                        NA_found = True
        if NA_found:
            print "    " + json_path
                 
        fd.close()



def main(json_dir):
     
    json_files = os.listdir(json_dir)  

    # First validation: looking for empty JSON files
    check_empty_json_files(json_dir, json_files)

    # Second validation: Detection of NA values inside any file
    check_NA_values(json_dir, json_files)

    # Total number of json files created
    print "The total number of JSON files created is " + str(len(json_files))    

if __name__ == "__main__":main(sys.argv[1])

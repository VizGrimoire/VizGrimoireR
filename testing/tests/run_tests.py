#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2014 Bitergia
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Authors:
#         Santiago Dueñas <sduenas@bitergia.com>
#

import os
import tempfile
import shutil
import subprocess
import unittest


def install_r_lib():
    r_lib_path = tempfile.mkdtemp(prefix='vizr-lib_')

    cmd = "R CMD INSTALL -l %s ../../vizgrimoire/" % r_lib_path
    retcode = subprocess.call(cmd, shell=True)

    if retcode != 0:
        shutil.rmtree(r_lib_path)
        raise RuntimeError("Error installing R library. Code error: %s" % retcode)

    os.environ['R_LIBS'] = r_lib_path
    return r_lib_path

def remove_r_lib(r_lib_path):
    shutil.rmtree(r_lib_path)
    os.environ['R_LIBS'] = ''


if __name__ == '__main__':
    r_lib_path = install_r_lib()

    # Look for tests and run them
    test_suite = unittest.TestLoader().discover('.', pattern='test*.py')
    unittest.TextTestRunner(buffer=True).run(test_suite)

    remove_r_lib(r_lib_path)

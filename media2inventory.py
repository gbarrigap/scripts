#!/usr/bin/python

#
# Copyright 2013 Guillermo Barriga Placencia <gbarrigap@yahoo.es>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

import sys
import argparse
import os
import re
import subprocess # Replaces os.command
import glob

# Init some global variables.
DEBUG = True

def video_file(f):
    return f.endswith(".mkv") or f.endswith(".mp4")

def make_inventory(args):
    mediainfo_str = "mediainfo --Output=XML"
    for f in filter(os.path.isdir, args.FILES):
        for v in filter(video_file, os.listdir(f)):
            mediainfo_str += ' "{}/{}"'.format(f, v)
    
    print mediainfo_str

def setup_parser():
    parser = argparse.ArgumentParser()
    # parser.add_argument("-o", "--output=")
    parser.add_argument("FILES", nargs = "+")
    parser.set_defaults(func = make_inventory)

    return parser

parser = setup_parser()
args = parser.parse_args()
args.func(args) # Executes the default function associated to the chosen operation.

sys.exit(1)

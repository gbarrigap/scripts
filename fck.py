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

#
# This scripts should be used to create or check CRC32 hashes
# associated to the file(s) specified by the user.
#

import sys # sys.argv
import os # os.rename

import binascii

from glob import glob
from zlib import crc32

import subprocess # Replaces os.command

# Init some global variables.
DEBUG = True

usage_message  = '''\
Usage: fck.py [command] [options] [file1 [file2 [...]]]

Commands:
    check             Perform a check on the file(s). Default.
    create            Create the checksum on the file(s)

Options:
    --dir=PATH      path of the directory with the files.
    --limit=LIMIT   how many files will be processed.
    --ask           asks for user confirmation of each action.
    --yes           on verbose execution, asumes "yes" to all prompts.
    --quiet         run silently (overrides '--ask').
'''

check  = True
create = False

files_dir = False
limit     = 0
ask       = False
yes       = False
quiet     = False

if DEBUG: print sys.argv

# http://code.activestate.com/recipes/541096-prompt-the-user-for-confirmation/
def confirm(prompt=None, resp=False):
    """prompts for yes or no response from the user. Returns True for yes and
    False for no.

    'resp' should be set to the default value assumed by the caller when
    user simply types ENTER.

    >>> confirm(prompt='Create Directory?', resp=True)
    Create Directory? [y]|n: 
    True
    >>> confirm(prompt='Create Directory?', resp=False)
    Create Directory? [n]|y: 
    False
    >>> confirm(prompt='Create Directory?', resp=False)
    Create Directory? [n]|y: y
    True

    """
    
    if prompt is None:
        prompt = 'Confirm'

    if resp:
        prompt = '%s [%s]|%s: ' % (prompt, 'y', 'n')
    else:
        prompt = '%s [%s]|%s: ' % (prompt, 'n', 'y')
        
    while True:
        ans = raw_input(prompt)
        if not ans:
            return resp
        if ans not in ['y', 'Y', 'n', 'N']:
            print 'please enter y or n.'
            continue
        if ans == 'y' or ans == 'Y':
            return True
        if ans == 'n' or ans == 'N':
            return False

def checksum(filename):
  mask = 0xffffffff
    
  with open(filename) as f:
    return hex(crc32(f.read()) & mask)[2:-1]
    #return str(crc32(f.read()) & 0xffffffff)

def CRC32_from_file(filename):
    buf = open(filename,'rb').read()
    buf = (binascii.crc32(buf) & 0xFFFFFFFF)
    return "%08X" % buf

def crc32_nanito(filename):
    file_crc32 = subprocess.check_output(["crc32", filename])
    file_crc32 = file_crc32.rstrip() # Removes the newline character
    return str.upper(file_crc32)

def check_file(filename):
    cksum = crc32_nanito(filename)
    result = "[OK]" if cksum.upper() in filename.upper() else "[Fail]"
    print "{} {}".format(filename, result)

def create_hash(filename):
    filename_parts = filename.split('.')
    filename_parts_count = len(filename_parts)
    cksum = crc32_nanito(filename)

    filename_parts[filename_parts_count - 2] += "_[" + str.upper(cksum) + "]" # + filename_parts[filename_parts_count - 1]
    filename_new = '.'.join(filename_parts)

    if ask:
        prompt_string = 'The file "' + filename + '" will be renamed to "' + filename_new + '". Continue'

        if confirm(prompt = prompt_string):
          os.rename(filename, filename_new)

    else:
        os.rename(filename, filename_new)
        print "{} renamed to {}".format(filename, filename_new)

def get_filenames_from_path(files_path):
    # Sanitizes directory name.
    if not files_path.endswith("/"): files_path += "/"

    filenames = glob("{}*".format(files_path)) # Get all the files of the given directory.

    return filenames

def check_operation(filename = False):
    global files_dir

    if filename:
        check_file(filename)

    elif files_dir and os.path.isdir(files_dir):
        filenames = get_filenames_from_path(files_dir)

        for filename in sorted(filenames):
            check_file(filename)

def create_operation(filename = False):
    global files_dir

    if filename:
        create_hash(filename)

    elif files_dir and os.path.isdir(files_dir):
        filenames = get_filenames_from_path(files_dir)

        for filename in sorted(filenames):
            create_hash(filename)

#sys.exit(usage_message)

for n in range(1, len(sys.argv)):
    arg = sys.argv[n]

    if   arg == "--check":  check = True
    elif arg == "--create": create = True

    elif arg.startswith("--dir="):   files_dir = arg.split("--dir=")[1]
    elif arg.startswith("--limit="): limit = int(arg.split("--limit=")[1])

    elif arg == "--recursive": recursive = True
    elif arg == "--ask":       ask = True
    elif arg == "--yes":       yes = True
    elif arg == "--quiet":     quiet = True

    else: sys.exit(usage_message)
        
# @todo: Initialize what is necessary.
filename = sys.argv[1]

if not create:
    check_operation()

elif create:
    create_operation()

else:
    sys.exit(usage_message)

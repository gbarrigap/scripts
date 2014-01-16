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
# Usage: see function "setup_parser".
#

import sys
import argparse
import os
import re
import subprocess # Replaces os.command

# Init some global variables.
DEBUG = False
CRC32_REGEX = "[0-9A-Fa-f]{8}"

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

def crc32(filename):
    file_crc32 = subprocess.check_output(["crc32", filename])
    file_crc32 = file_crc32.rstrip() # Removes the newline character
    return str.upper(file_crc32)

def get_hashed_filename(filename, cksum):
    filename_parts = filename.split('.')
    filename_parts_count = len(filename_parts)
    filename_parts[filename_parts_count - 2] += "_[" + str.upper(cksum) + "]" # + filename_parts[filename_parts_count - 1]
    filename_new = '.'.join(filename_parts)

    return filename_new

def is_hashed(filename):
    return re.search(CRC32_REGEX, filename)

def is_hash_ok(filename):
    return crc32(filename).upper() in filename.upper()

def rename_file(filename_old, filename_new, message = False):
    os.rename(filename_old, filename_new)

    if message: print message

def checkable_filenames(filenames, force_check):
    for filename in filenames:
        if os.path.isfile(filename) and (force_check or is_hashed(filename)):
            yield filename

def check_op(args):
    filenames = list(checkable_filenames(args.FILES, args.force))

    for filename in filenames:
        if not is_hash_ok(filename):
            print "{} [Fail]".format(filename)

        elif args.verbose:
            print "{} [OK]".format(filename)
    
    if not len(filenames):
        print "No hashed files found!"

def filenames_for_generation(filenames, skip_hashed_filenames):
    for filename in filenames:
        if os.path.isfile(filename):
            if skip_hashed_filenames and is_hashed(filename):
                continue
            else:
                yield filename

def generate_op(args):
    filenames = list(filenames_for_generation(args.FILES, args.skip))

    for filename in filenames:
        cksum = crc32(filename)
        filename_with_hash = get_hashed_filename(filename, cksum)
        message = "{} to {}".format(filename, filename_with_hash)

        if args.quiet:
            rename_file(filename, filename_with_hash)
        
        elif args.yes:
            rename_file(filename, filename_with_hash, message)
        
        elif confirm(message):
            rename_file(filename, filename_with_hash)

    if not len(filenames):
        print "No hashes generated!"

def setup_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest = "operation_mode")

    # Check operation
    parser_check = subparsers.add_parser("check", help = "Performs a check")
    parser_check.add_argument("-n", "--from-filename", action = "store_true")
    parser_check.add_argument("-f", "--from-file",     action = "store_true")
    parser_check.add_argument("-v", "--verbose",       action = "store_true", help = "Shows [OK] and [Fail] results.")
    parser_check.add_argument("-F", "--force",         action = "store_true", help = "Check files with no apparent hash present.")
    parser_check.add_argument("FILES", nargs = "+")
    parser_check.set_defaults(func = check_op)

    # Generate operation
    parser_generate = subparsers.add_parser("generate", help = "Generate hashes and rename files accordingly.")
    parser_generate.add_argument("-n", "--to-filename", action = "store_true")
    parser_generate.add_argument("-f", "--to-file",     action = "store_true")
    parser_generate.add_argument("-s", "--skip",        action = "store_true", help = "Does not process files already hashed.")
    
    parser_generate_yes_quiet_group = parser_generate.add_mutually_exclusive_group()
    parser_generate_yes_quiet_group.add_argument("-y", "--yes",         action = "store_true")
    parser_generate_yes_quiet_group.add_argument("-q", "--quiet",       action = "store_true", help = "Does not show anything. Implies --yes.")
    
    parser_generate.add_argument("FILES", nargs = "+")
    parser_generate.set_defaults(func = generate_op)

    # Update operation
    # --update-all
    # --update-some

    return parser

parser = setup_parser()
args = parser.parse_args()
args.func(args) # Executes the default function associated to the chosen operation.

sys.exit(1)

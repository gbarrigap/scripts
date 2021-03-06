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
# This script, should be used to concatenate video files obtained
# from a streamed source, such as:
# curl http://edge-30-us.edge.mdstrm.com/media-us/_definst_/smil:52a338f4362d187131000005/media_b623000_[0-247].ts?access_token=53e7035668cec94c17f1649a27cff2d4-9dbc290e842d6c80da12a499a5c3643d -o "#1.ts"
# 

import sys # sys.argv
import os # os.listdir
import re

DEBUG = True

if DEBUG: print sys.argv

def tryint(s):
    try:
        return int(s)
    except:
        return s
    
def alphanum_key(s):
    # Turn a string into a list of string and number chunks. "z23a" -> ["z", 23, "a"]
    return [ tryint(c) for c in re.split('([0-9]+)', s) ]

def sort_nicely(l):
    # Sort the given list in the way that humans expect.
    l.sort(key=alphanum_key)

# Filters...
def filter_by_filename_extension(files, filename_ext, limit):
  counter = 0
  for f in files:
    if counter < limit:
      if f.endswith(".ts"):
        counter += 1
        yield f

# Check args and print usage or continue, accordingly.
usage_message  = '''\
Usage: vidcat.py --dir=PATH --out=FILENAME [--ext=EXT] [--limit=LIMIT] [--ask] [--yes] [--quiet]

    --dir=/path/to/dir/ -d /path/to/dir/ path of the directory with the files.
    --out=out_file      -o out_file      name of the output file.
    --ext=ext           -e ext           filters by file extension
    --limit=limit       -l limit         how many files will be processed.
    --ask               -a               asks for user confirmation of each action.
    --yes               -y               on verbose execution, asumes "yes" to all prompts.
    --quiet             -q               run silently (overrides '--ask').
'''

def show_help():
  print usage_message
  sys.exit(0)

# Init some global variables.
limit = 0
ask   = False
yes   = False
quiet = False

for n in range(1, len(sys.argv)):
  arg = sys.argv[n]

  # @todo Handle short arguments!
  #
  #if arg.startswith("--dir="):
  #elif arg.startswith("-d"):
  #elif arg.startswith("--out="):
  #elif arg.startswith("-o "):
  #elif arg.startswith("--ext="):
  #elif arg.startswith("-e "):
  #elif arg.startswith("--limit="):
  #elif arg.startswith("-l "):

  if arg.startswith("--dir="):     vids_dir = arg.split("--dir=")[1]
  elif arg.startswith("--out="):   filename_out = arg.split("--out=")[1]
  elif arg.startswith("--ext="):   filename_ext = arg.split("--ext=")[1]
  elif arg.startswith("--limit="): limit = int(arg.split("--limit=")[1])
  elif arg == "--ask":             ask = True
  elif arg == "--quiet":           quiet = True
  elif arg == "--help":            show_help()
  else:                            sys.exit(usage_message)

files = os.listdir(vids_dir)
sort_nicely(files)

files       = list(filter_by_filename_extension(files, filename_ext, limit if limit > 0 else len(files)))
files_count = len(files)
files_firts = files[0]
files_last  = files[files_count - 1]

# Calculate the number of digits of the file count,
# to use it for padding the counter in the progress indicator.
files_count_char_count = len(str(files_count))

if ask and not quiet:
  prompt = "I'm about to process {} files; from {} to {}. Shall I continue with the task, sire? [y/n]"
  raw_input(prompt.format(files_count, files_firts, files_last))

processed_files_count = 0
for n in range(files_count):
  f = files[n]
  command = "cat {}{} {} {}".format(vids_dir, f, (">" if n is 0 else ">>"), filename_out)
  message = "About to execute {}".format(command)
  
  if ask and not quiet:
    raw_input("About to execute {}".format(command))
  
  elif not quiet:
    print "Executing {}".format(command),

  os.system(command)

  processed_files_count += 1
  if not quiet: print "[{}/{}]".format(str(processed_files_count).rjust(files_count_char_count), files_count)

if not quiet: print "{} files where successfully processed. Bye!".format(processed_files_count)

sys.exit(0)


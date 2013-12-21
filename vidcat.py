#!/usr/bin/python

import sys # sys.argv
import os # os.listdir
import re

DEBUG = True

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

#print len(sys.argv)
#for a in sys.argv:
#  print a

#vids_dir     = sys.argv[1]
#filename_out = sys.argv[2] if len(sys.argv) > 2 else False
#limit        = sys.argv[3] if len(sys.argv) > 3 else False
#filename_ext = sys.argv[4] if len(sys.argv) > 4 else False

# Check args and print usage or continue, accordingly.
#
# --dir=/path/to/dir/ -d /path/to/dir/ path of the directory with the files.
# --out=out_file      -o out_file      name of the output file.
# --ext=ext           -e ext           filters by file extension
# --limit=limit       -l limit         how many files will be processed.
# --verbose           -v               shows the name of each processed file.
# --yes               -y               on verbose execution, asumes "yes" to all prompts.

for n in range(1, len(sys.argv)):
  arg = sys.argv[n]

  #if arg.startswith("--dir="):
  #  vids_dir = arg.split("--dir=")[1]
  #elif arg.startswith("-d"):
  #  vids_dir = sys.argv[n + 1]
  #
  #elif arg.startswith("--out="):
  #  filename_out = arg.split("--out=")[1]
  #elif arg.startswith("-o "):
  #  filename_out = arg.split("-o ")[1]
  #
  #elif arg.startswith("--ext="):
  #  filename_ext = arg.split("--ext=")[1]
  #elif arg.startswith("-e "):
  #  filename_ext = arg.split("-e ")[1]
  #
  #elif arg.startswith("--limit="):
  #  limit = arg.split("--limit=")[1]
  #elif arg.startswith("-l "):
  #  limit = arg.split("-l ")[1]

  if arg.startswith("--dir="):
    vids_dir = arg.split("--dir=")[1]
  
  elif arg.startswith("--out="):
    filename_out = arg.split("--out=")[1]
  
  elif arg.startswith("--ext="):
    filename_ext = arg.split("--ext=")[1]
  
  elif arg.startswith("--limit="):
    limit = int(arg.split("--limit=")[1])

  else:
    #usage_msg = "Usage: vidcat.py [--dir=PATH | -d PATH] [--out=FILENAME | -o FILENAME] [--ext=EXT | -e EXT] [--limit=LIMIT | -l LIMIT]"
    usage_msg = "Usage: vidcat.py --dir=PATH --out=FILENAME [--ext=EXT] [--limit=LIMIT]"
    sys.exit(usage_msg)

print "vids_dir: {}\nfilename_out: {}\nfilename_ext: {}\nlimit: {}".format(vids_dir, filename_out, filename_ext, limit)
#sys.exit("Probando, probando...")

files = os.listdir(vids_dir)
sort_nicely(files)

# If there is a limit, it will be used as the file count.
files_count = int(limit) if int(limit) > 0 else len(files)

first_file  = files[0]
last_file   = files[files_count - 1]

#print "Launching filter with limit: {}".format(limit)
filtered_files       = list(filter_by_filename_extension(files, filename_ext, limit if limit > 0 else len(files)))
filtered_files_count = len(filtered_files)
filtered_files_firts = filtered_files[0]
filtered_files_last  = filtered_files[filtered_files_count - 1]

files       = list(filter_by_filename_extension(files, filename_ext, limit if limit > 0 else len(files)))
files_count = len(files)
files_firts = files[0]
files_last  = files[files_count - 1]
#for e in eggs:
#  print e
#sys.exit()

## Filter the files if necessary.
#raw_input("About to print filtered files [{}]".format(limit if limit > 0 else len(files)))
#for f in filter_by_filename_extension(files, filename_ext, limit if limit > 0 else len(files)):
#  print f
##for n in range(files_count):
##  print files[n]
#raw_input("Filtered files printed!")

#prompt = "I'm about to process {} files; from {} to {}. Shall I continue with the task, sire? [y/n]".format(files_count, first_file, last_file)
prompt = "I'm about to process {} files; from {} to {}. Shall I continue with the task, sire? [y/n]"
#raw_input(prompt.format(filtered_files_count, filtered_files_firts, filtered_files_last))
raw_input(prompt.format(files_count, files_firts, files_last))
#raw_input(prompt)

#for n in range(filtered_files_count):
#  f = filtered_files[n]
#  command = "cat {} {} {}".format(f, (">" if n is 0 else ">>"), filename_out)
#  if DEBUG: raw_input("About to execute {}".format(command))
for n in range(files_count):
  f = files[n]
  command = "cat {} {} {}".format(f, (">" if n is 0 else ">>"), filename_out)
  if DEBUG: raw_input("About to execute {}".format(command))

sys.exit("Bye!")

#processed_files_count = 0
#for n in range(files_count):
#  command = "cat {} {} {}".format(files[n], (">" if n is 0 else ">>"), filename_out)
#
#  #if DEBUG raw_input("About to execute {}".format(command))
#  #if DEBUG raw_input("About to execute {}".format(command))
#  print command
#  
#  processed_files_count += 1
#
#print "{} files processed. Program terminated!".format(processed_files_count)

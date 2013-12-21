#!/usr/bin/python

import sys # sys.argv
import os # os.system

DEBUG = False

filename_base = sys.argv[1]
file_count    = int(sys.argv[2])
filename_out  = sys.argv[3]

# Check args and print usage or continue, accordingly.

for n in range(file_count):
  command = "cat {}_{}.ts {} {}".format(filename_base, n, (">" if n is 0 else ">>"), filename_out)
  
  if DEBUG raw_input("About to execute {}".format(command))
  
  os.system(command)

print "{} files processed. Program terminated!".format(file_count)

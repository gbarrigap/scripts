#!/usr/bin/python

import sys # sys.argv
import os # os.rename

import binascii

from glob import glob
from zlib import crc32

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
        
#files = glob('*.mkv')

#print 'Number of arguments:', len(sys.argv), 'arguments.'
#print 'Argument List:', str(sys.argv)

filename = sys.argv[1]

filename_parts = filename.split('.')
filename_parts_count = len(filename_parts)
#cksum = checksum(sys.argv[1])
cksum = CRC32_from_file(sys.argv[1])

#print cksum
#print cksum2
#sys.exit("Just, testing...")

filename_parts[filename_parts_count - 2] += "_[" + str.upper(cksum) + "]" # + filename_parts[filename_parts_count - 1]
filename_new = '.'.join(filename_parts)

prompt_string = 'The file "' + filename + '" will be renamed to "' + filename_new + '". Continue'

if confirm(prompt = prompt_string):
  # Rename the file
  os.rename(filename, filename_new)

#for f in sorted(files):
#  cksum = checksum(f)
#    
#  result = 'OK' if cksum in f or cksum.upper() in f else 'FAILED'
#  print '%s: %s' % (f, result)

#print 'Program terminated!'

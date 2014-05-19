#!/usr/bin/env ruby

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#
# Copyright 2014 Guillermo Barriga Placencia <gbarrigap@yahoo.es>
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
# Usage: see "fck --help"
#

#
# This script depends on the "Trollop" gem.
#
# "gem install trollop" should do the trick.
#
# @see http://trollop.rubyforge.org/
#

#
# The next table, summarizes the time it took to run this script
# on the developer's computer, with some arbitrary file chunk sizes,
# using the command
#
#   $time fck check file
# 
# given a 4687385841 bytes size binary file.
#
# o----------------o-----------o-----------o-----------o---------o
# |   chunk_size   |    real   |    user   |    sys    | verbose |
# o----------------o-----------o-----------o-----------o---------o
# | 512            |  2m4.402s | 0m33.944s |  0m8.296s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024           | 1m22.841s | 0m24.496s | 0m10.032s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024           | 1m58.320s | 0m24.860s | 0m10.636s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024           | 1m59.245s | 0m24.376s | 0m10.240s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024           | 5m28.082s | 1m17.564s | 0m38.836s |  YES    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024      | 1m26.112s | 0m15.084s | 0m11.148s |  YES    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024      | 1m25.959s | 0m15.444s | 0m11.132s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024      | 1m50.710s | 0m15.320s | 0m11.380s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024*10   | 1m28.748s | 0m12.252s | 0m11.380s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024*20   | 1m28.150s | 0m11.088s | 0m11.188s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024*40   | 1m31.976s | 0m11.640s |  0m8.868s |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024*100  | 1m34.911s | 0m10.188s | 0m11.580s |  YES    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*1024*100  | 1m55.434s | 0m10.092s | 0m11.472s |  YES    |
# o----------------o-----------o-----------o-----------o---------o
# | 1024*          | 000000000 | 000000000 | 000000000 |   NO    |
# o----------------o-----------o-----------o-----------o---------o
# 
# Note: crc32 native implementation reference results:
#
#   real  1m31.887s
#   user  0m14.148s
#   sys 0m5.012s
# 

#
# Version control table
#
# o------------o-------------------------------------------------------------o
# |    Date    | Description                                                 |
# o------------o-------------------------------------------------------------o
# | 2014-05-18 | * Fixes big-file bug                                        |
# |            | * Adds performance table                                    |
# |            | * Adds version control table                                |
# |            | * Adds documentation to some processes                      |
# o------------o-------------------------------------------------------------o
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require "zlib"
require "trollop"

# Init some global constants.
DEBUG = false
CRC32_REGEX = /[0-9A-Fa-f]{8}/
DEFAULT_DELIMITER = "_"
DEFAULT_FILE_CHUNK_SIZE = 1024*1024*30 # 30MB

#
# Extensions to the *String* class,
# to allow easy manipulation of filenames and hashes.
#
class String

  def file?
    File.file?(self)
  end

  def hashed?
    CRC32_REGEX === self
  end

  def not_hashed?
    not self.hashed?
  end

end

#
# Extensions to the *File* class,
# to allow easy file reading by chunks of data.
#
class File

  def each_chunk(chunk_size = DEFAULT_FILE_CHUNK_SIZE)
    yield self.read(chunk_size) until self.eof?
  end

  def each_chunk_partial(chunk_size = DEFAULT_FILE_CHUNK_SIZE)
    yield self.read(chunk_size) until self.eof?
  end

end

#
# @param hash An integer CRC32 hash
# @return An uppercase string of the received number's hexadecimal value
#
def format_hash(hash)
  hash.to_s(16).rjust(8, "0").upcase
end

#
# Calculates de CRC32 hash of a big file, by processing it by parts.
#
# @param filename The filename of the file to be processed
# @param chunk_size The file will be processed by this size in bytes
# @returns The CRC32 hash of the received file.
# @see crc32()
#
def crc32_bigfile(filename, chunk_size = DEFAULT_FILE_CHUNK_SIZE)
  hash = 0;
  open(filename, "rb") do |f|
    f.each_chunk_partial(chunk_size) do |chunk|
      #
      # Processes the opened file by reading it in chunks
      # of the received value; if no value is received, it
      # defaults to DEFAULT_FILE_CHUNK_SIZE.
      #
      # For each chunk, the hash is calculated using the
      # function crc32(string, hash), where the string
      # is the source of the calculation, the chunk, and
      # the hash, is the accumulated result of the hash
      # calculation. At the end of the iteration, this
      # hash will contain the actual hash of the file.
      #
      hash = Zlib.crc32(chunk, hash)
    end
  end

  format_hash(hash)
end

#
# @param filename The filename of the file to be processed
# @returns The uppercase string of the received file's CRC32 hash value.
# @see crc32_bigfile
#
def crc32(filename)
  format_hash(Zlib.crc32(open(filename).read()))
rescue => detail
  case detail.message
  when "file too big for single read"
    puts "Big file; calculating in chunks..."
    crc32_bigfile(filename)
  else
    puts detail
  end
end

def get_hashed_filename(filename, hash, delimiter)
  suffix = File.extname(filename)
  base = File.basename(filename, suffix)

  "#{base}#{delimiter}[#{hash}]#{suffix}"
end

def hash_ok?(filename)
  hash = crc32(filename)

  true & filename.match(hash)
end

def generate(opts, filenames)

  # Keep only valid filenames.
  filenames.select!(&:file?)

  # When skipping hashed filenames,
  # keep only filenames without hash.
  filenames.select!(&:not_hashed?) if opts[:skip]

  filenames.each do |filename|
    hash = crc32(filename)
    hashed_filename = get_hashed_filename(filename, hash, opts.delimiter)
    
    # Unless running quietly,
    # show the user what is happenning.
    puts "#{filename} renamed to #{hashed_filename}" unless opts[:quiet]

    # Unless in dry run mode,
    # rename the file.
    File.rename(filename, hashed_filename) unless opts[:dry_run]
  end
end

def check(opts, filenames)
  
  # Variables to keep count.
  # file_count, ok_count, fail_count = 0, 0, 0
  file_count = ok_count = fail_count = 0

  # Keep only valid filenames.
  filenames.select!(&:file?)

  # Unless in force mode,
  # keep only filenames with a valid hash.
  filenames.select!(&:hashed?) unless opts[:force]

  filenames.each do |filename|
    file_count += 1
    if hash_ok?(filename)
      ok_count += 1

      # When running verbosely,
      # show OK files.
      puts "#{filename} [OK]" if opts[:verbose]
    else
      fail_count += 1

      # Always show failing files.
      puts "#{filename} [Fail]"
    end
  end

  puts "Total: #{file_count} / OK: #{ok_count} / Fail: #{fail_count}"
end

#
# Setup parser!
#
SUB_COMMANDS = %w(generate check)
global_opts = Trollop::options do
  banner "Usage: fck.rb generate|check [options] FILES"
  stop_on SUB_COMMANDS
end

cmd = ARGV.shift # get the subcommand
cmd_opts = case cmd
  when "generate" # parse generate options
    Trollop::options do
      opt :skip, "Skip files already hashed"
      opt :delimiter, "Character to separate the hash from the filename", {:default => DEFAULT_DELIMITER}
      opt :dry_run, "Don't actually do anything.", :short => "-n"
      opt :quiet, "Run without showing progress."
    end
  when "check" # parse check options
    Trollop::options do
      opt :verbose, "Print extra information."
      opt :force, "Check files with no apparent hash present"
    end
  else
    Trollop::die "unknown subcommand #{cmd.inspect}"
  end

# Check mutually exclusive options.
Trollop::die "--dry-run and --quiet are mutually exclusive!" if cmd == "generate" and cmd_opts[:dry_run] and cmd_opts[:quiet]

case cmd
when "generate"
  generate(cmd_opts, ARGV)
when "check"
  check(cmd_opts, ARGV)
end

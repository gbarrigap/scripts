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
# | 2014-05-18 | * Fixes big-file bug.                                       |
# |            | * Adds performance table.                                   |
# |            | * Adds version control table.                               |
# |            | * Adds documentation to some processes.                     |
# o------------o-------------------------------------------------------------o
# | 2014-05-24 | * Changes default behaviour to read file by chunks.         |
# |            | * Adds single_read option.                                  |
# |            | * Adds chunk_size option.                                   |
# |            | * Adds verbose option on generation.                        |
# |            | * Standardizes calls to option variables by using dot       |
# |            |   notation (object like) instead of array keys.             |
# |            | * Changes filenames and Trollop options to be global        |
# |            |   variables, for easier access within functions.            |
# |            | * Adds some minor documentation.                            |
# o------------o-------------------------------------------------------------o
# |            | *                                                           |
# o------------o-------------------------------------------------------------o
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require "zlib"
require "trollop"

# Init some global constants.
DEBUG = false
CRC32_REGEX = /[0-9A-Fa-f]{8}/
DEFAULT_DELIMITER = "_"
DEFAULT_FILE_CHUNK_SIZE = 2**20 # 1MB

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
# @returns The CRC32 hash of the received file.
# @see crc32()
#
def crc32_by_chunks(filename)
  # If no custom chunk size is given,
  # use the default value.
  chunk_size = $cmd_opts.chunk_size ? $cmd_opts.chunk_size : DEFAULT_FILE_CHUNK_SIZE

  puts "#{filename}: reading file by chunks of #{chunk_size}." if DEBUG

  hash = 0;
  open(filename, "rb") do |f|
    f.each_chunk(chunk_size) do |chunk|
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
# Calculates the CRC32 hash of the received file
# reading the whole file into memory.
#
# @param filename the name of the file to be processed
# @returns the CRC32 hash of the received file
#
def crc32_single_read(filename)
  puts "#{filename}: trying to calculate hash in single read mode" if DEBUG

  format_hash(Zlib.crc32(open(filename).read()))
end

#
# @param filename The filename of the file to be processed
# @returns The uppercase string of the received file's CRC32 hash value.
# @see crc32_by_chunks
#
def crc32(filename)
  # Determine the reading method to be used.
  $cmd_opts.single_read ? crc32_single_read(filename) : crc32_by_chunks(filename)
rescue => detail
  case detail.message
  when "file too big for single read"
    puts "#{filename}: big file; calculating in chunks" if DEBUG

    crc32_by_chunks(filename)
  else
    puts detail
  end
end

#
# Apply the received hash and delimiter, if any,
# to the received filename.
#
# @param filename
# @param hash
# @param delimiter
# @return the filename with the received hash,
#         separated by the optional delimiter.
#
def get_hashed_filename(filename, hash, delimiter)
  suffix = File.extname(filename)
  base = File.basename(filename, suffix)

  "#{base}#{delimiter}[#{hash}]#{suffix}"
end

#
# Determines if the hash of the received file is correct.
#
# @param filename the name of the file with the hash to test.
# @returns boolean true if the hash is correct; false otherwise.
#
def hash_ok?(filename)
  # Calculate the hash of the file,
  # and match it against its filename.
  true & filename.match(crc32(filename))
end

def generate()
  # When skipping hashed filenames,
  # keep only filenames without hash.
  $filenames.select!(&:not_hashed?) if $cmd_opts.skip

  $filenames.each do |filename|
    hash = crc32(filename)
    hashed_filename = get_hashed_filename(filename, hash, $cmd_opts.delimiter)
    
    # Unless running quietly,
    # show the user what is happenning.
    puts "#{filename} renamed to #{hashed_filename}" unless $cmd_opts.quiet

    # Unless in dry run mode,
    # rename the file.
    File.rename(filename, hashed_filename) unless $cmd_opts.dry_run
  end
end

def check()
  # Variables to keep count.
  file_count, ok_count, fail_count = 0, 0, 0

  # Unless in force mode,
  # keep only filenames with a valid hash.
  $filenames.select!(&:hashed?) unless $cmd_opts.force

  $filenames.each do |filename|
    file_count += 1
    if hash_ok?(filename)
      ok_count += 1

      # When running verbosely,
      # show OK files.
      puts "#{filename} [OK]" if $cmd_opts.verbose
    else
      fail_count += 1

      # Always show failing files.
      puts "#{filename} [Fail]"
    end
  end

  # Show the results of the process.
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

verbose_explain     = "Show what is happenning during the process"
single_read_explain = "Read the whole file in memory; do not split it in smaller chunks. If the file is too large, chunks will be used instead"
chunk_size_explain  = "Split the files in chunks of this size in bytes for reading"

cmd = ARGV.shift # get the subcommand
$cmd_opts = case cmd
  when "generate" # parse generate options
    Trollop::options do
      opt :skip, "Skip files already hashed"
      opt :delimiter, "Character to separate the hash from the filename", {:default => DEFAULT_DELIMITER}
      opt :dry_run, "Don't actually do anything", :short => "-n"
      opt :quiet, "Run without showing progress"
      opt :single_read, single_read_explain
      opt :chunk_size, chunk_size_explain, :type => :int
      opt :verbose, verbose_explain
    end
  when "check" # parse check options
    Trollop::options do
      opt :verbose, verbose_explain
      opt :force, "Check files with no apparent hash present. Will be deprecated in future version."
      opt :single_read, single_read_explain
      opt :chunk_size, chunk_size_explain, :type => :int
    end
  else
    Trollop::die "unknown subcommand #{cmd.inspect}"
  end

# Check mutually exclusive options.
Trollop::die "--quiet and --verbose are mutually exclusive!" if cmd == "generate" and $cmd_opts[:quiet] and $cmd_opts[:verbose]
Trollop::die "--dry-run and --quiet are mutually exclusive!" if cmd == "generate" and $cmd_opts[:dry_run] and $cmd_opts[:quiet]
Trollop::die "--single-read and --chunk-size are mutually exclusive!" if $cmd_opts[:single_read] and $cmd_opts[:chunk_size]

# Get the list of filenames to work with.
# Keep only the valid ones.
$filenames = ARGV.select(&:file?)

case cmd
when "generate"
  generate()
when "check"
  check()
end

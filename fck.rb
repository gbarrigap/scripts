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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require "zlib"
require "trollop"

# Init some global variables.
DEBUG = false
CRC32_REGEX = /[0-9A-Fa-f]{8}/
DEFAULT_DELIMITER = "_"

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

def crc32(filename)
  Zlib.crc32(open(filename).read()).to_s(16).rjust(8, "0").upcase
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

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
# This scripts should be used to
#
# Usage: see --help
#

#
# TODO
#   * Show the event when it is found, not at the end of this script.
#   * Use command line arguments to receive a file to dump the output.
#   * Use command line arguments to receive the range, start or end value.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require "net/http"
require "open-uri"
require "nokogiri"

VERBOSE = true # TODO receive as command line argument.

base_url = "http://live.redbull.tv/events/"
url_range = (0..400)

url_range.each do |event_number|
  event_url = "#{base_url}#{event_number}"

  if Net::HTTP.get_response(URI.parse(event_url)).code.to_i == 200
    event_page = Nokogiri::HTML(open(event_url))
    event_title = event_page.at('meta[property="og:title"]')['content']
    event = "#{event_url}: #{event_title}"

    puts event
  else
    puts "#{event_url}: No event" if VERBOSE
  end
end

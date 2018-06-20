#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/local_storage"

# Usage:
#
#  - Must be ran as an independent Ruby script. Removes data from /tmp/gencat/
#  invitations and trips data, between dates if passed as argument, for any
#  date elsewhere. It raises an error if there is no data when dates argument
#  is not present
#
# Arguments:
#  - 0: Path. Required. The path below /tmp/gencat/ from which the contents will be removed
#
# Samples:
#
#   /path/to/project/operations/gobierto_people/clear-path/run.rb downloads/datasets
#

if ARGV.length < 1
  raise "Path argument is required."
end

path_arg = ARGV[0]
puts "[START] clear-path/run.rb with path=#{ path_arg }"

path = Utils::LocalStorage.new(path: path_arg)
path.delete

puts "Deleted path #{ path.file_path }"

puts "[END] clear-path/run.rb"
exit 0

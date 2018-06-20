#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/trips_importer"
require_relative "../../../utils/local_storage"

# Usage:
#
#  - Must be ran as a gobierto runner.
#
# Arguments:
#  - 0: Path to csv file conaining data to be transformed/loaded
#  - 1: Domain of site where the transformed data has to be loaded
#
# Samples:
#
#   /path/to/project/operations/gobierto_people/import-trips/run.rb /tmp/gencat/downloads/datasets/trips.csv gencat.gobierto.test
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb path domain"
end

path_arg = ARGV[0]
file = Utils::LocalStorage.new(path: path_arg)
site = Site.find_by_domain ARGV[1]

puts "[START] import-trips/run.rb with path=#{ path_arg }, domain=#{ site.domain }"

if file.exist?
  importer = Utils::TripsImporter.new(path: file.file_path, site: site)
  puts "Importing trips from file: #{ file.file_path }"
  importer.import!
else
  puts "Trips file is not present. Nothing to do"
end

puts "[END] import-trips/run.rb"
exit 0

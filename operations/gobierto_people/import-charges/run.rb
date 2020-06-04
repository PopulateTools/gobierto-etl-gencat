#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/charges_importer"
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
#   /path/to/project/operations/gobierto_people/import-charges/run.rb /tmp/gencat/downloads/datasets/charges.csv gencat.gobierto.test
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb path domain"
end

path_arg = ARGV[0]
file = Utils::LocalStorage.new(path: path_arg)
site = Site.find_by_domain ARGV[1]

puts "[START] import-charges/run.rb with path=#{ path_arg }, domain=#{ site.domain }"

if file.exist?
  importer = Utils::ChargesImporter.new(path: file.file_path, site: site)
  puts "Importing charges from file: #{ file.file_path }"
  importer.import!
  if importer.errors?
    errors_output = Utils::LocalStorage.new(path: "output/charges_errors.txt", content: importer.errors.pretty_inspect)
    errors_output.save
    puts "Some errors have prevented the load of some data. A report has been generated in #{ errors_output.file_path }"
    exit(-1)
  end
else
  puts "Charges file is not present. Nothing to do"
end

puts "[END] import-charges/run.rb"
exit 0

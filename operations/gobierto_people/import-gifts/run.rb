#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/gifts_importer"
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
#   /path/to/project/operations/gobierto_people/import-gifts/run.rb /tmp/gencat/downloads/datasets/gifts.csv gencat.gobierto.test
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb path domain"
end

path_arg = ARGV[0]
file = Utils::LocalStorage.new(path: path_arg)
site = Site.find_by_domain ARGV[1]

puts "[START] import-gifts/run.rb with path=#{ path_arg }, domain=#{ site.domain }"

if file.exist?
  importer = Utils::GiftsImporter.new(path: file.file_path, site: site)
  puts "Importing gifts from file: #{ file.file_path }"
  importer.import!
  if importer.errors?
    errors_output = Utils::LocalStorage.new(path: "output/gifts_errors.txt", content: importer.errors.pretty_inspect)
    start_query_date = Utils::LocalStorage.new(path: "output/start_query_date.txt")
    first_error_date = importer.first_record_with_errors_date
    if !start_query_date.exist? || (first_error_date && DateTime.parse(start_query_date.content) > first_error_date)
      start_query_date.content = first_error_date
      start_query_date.save
    end
    errors_output.save
    puts "Some errors have prevented the load of some data. A report has been generated in #{ errors_output.file_path }"
    puts "The first record with errors was updated at #{ first_error_date }"
    exit(-1)
  end
else
  puts "Gifts file is not present. Nothing to do"
end

puts "[END] import-gifts/run.rb"
exit 0

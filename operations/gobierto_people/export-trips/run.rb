#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/local_storage"

# Usage:
#
#  - Must be ran as a gobierto runner.
#
# Arguments:
#  - 0: Domain of site where the transformed data has to be loaded
#  - 1: Output file name
#
# Samples:
#
#   /path/to/project/operations/gobierto_people/import-trips/run.rb gencat.gobierto.test /tmp/gencat/downloads/datasets/trips.csv
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb path domain"
end

site = Site.find_by_domain! ARGV[0]
path_arg = ARGV[1]
file = Utils::LocalStorage.new(path: path_arg)

puts "[START] export-trips/run.rb with path=#{ path_arg }, domain=#{ site.domain }"

headers = %W( gobierto_id department_name department_id person_name person_charge person_slug lat lon destination_name start_date
              end_date purpose agenda food_expenses other_expenses total_expenses transport_expenses accomodation_expenses
              country country_name city_name )

CSV.open(file.file_path, "wb") do |csv|
  csv << headers
  site.trips.all.select{ |t| t.destinations_meta["destinations"].length > 0 }.each do |trip|
    trip.destinations_meta["destinations"].each do |destination|
      csv << [
        trip.id, trip.department.name, trip.department.id, trip.person.name, trip.person.charge, trip.person.slug, destination["lat"], destination["lon"],
        destination["name"], trip.start_date.to_s, trip.end_date.to_s, trip.meta["purpose"], trip.description, trip.meta["food_expenses"],
        trip.meta["other_expenses"], trip.meta["total_expenses"], trip.meta["transport_expenses"], trip.meta["accomodation_expenses"],
        destination["country_code"], destination["country_name"], destination["city_name"]
      ]
    end
  end
end

puts "[END] import-trips/run.rb"
exit 0

#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

# Usage:
#
#  - Must be ran as a gobierto runner.
#
# Arguments:
#  - 1: Domain of site where the people data has to be removed
#
# Samples:
#
#   /path/to/project/operations/gobierto_people/clear-previous-data/run.rb gencat.gobierto.test
#

if ARGV.length != 1
  raise "Incorrect number of arguments. Execute run.rb domain"
end

site = Site.find_by_domain ARGV[0]

puts "[START] clear-previous-data/run.rb with domain=#{ site.domain }"

if site.present?
  site.events.with_deleted.each do |event|
    event.really_destroy!
  end
  site.people.destroy_all
  site.gifts.destroy_all
  site.invitations.destroy_all
  site.trips.destroy_all
  site.departments.destroy_all
  site.interest_groups.destroy_all
  site.collections.where(container_type: "GobiertoPeople::Person").destroy_all
  site.collection_items.where(item_type: "GobiertoCalendars::Event").destroy_all
else
  puts "Site not found. Nothing to do"
end

puts "[END] clear-previous-data/run.rb"
exit 0

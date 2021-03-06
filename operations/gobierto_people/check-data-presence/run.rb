#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require
require_relative "../../../utils/origin_dataset"
require_relative "../../../utils/local_storage"

# Usage:
#
#  - Must be ran as an independent Ruby script. Checks the presence of gifts,
#  invitations and trips data, between dates if passed as argument, for any
#  date elsewhere. It raises an error if there is no data when dates argument
#  is not present
#
# Arguments:
#  - 0: Rails env
#  - 1: Dataset. Required. Options events, gifts, invitations, charges or all
#  - 2: Basic auth credentials. Required. Some datasets may require requests
#       with basic auth. The option must have the form "username:password"
#  - 3: Start Date. Optional. If value is "forever", data of any time
#       is requested. If blank the start date will use the last
#       execution date if existed.
#  - 4: End Date. Optional. Ignored if previous argument is "forever".
#
# Samples:
#
#   /path/to/project/operations/gobierto_people/check-data-presence/run.rb staging gifts username:password 2018-06-01 2018-07-01
#

if ARGV.length < 3
  raise "Rails env, dataset and basic auth credentials arguments are required. Options for dataset: #{ dataset_opts.join("|") }"
end

rails_env = ARGV[0]
valid_datasets = Utils::OriginDataset.valid_datasets(rails_env)
dataset_opts = valid_datasets + [:all]

if !dataset_opts.include? ARGV[1].to_sym
  raise "Invalid dataset argument. Options: #{ dataset_opts.join("|") }"
end

datasets = ARGV[1] == "all" ? valid_datasets : [ARGV[1].to_sym]
basic_auth_credentials = ARGV[2]

start_date = end_date = nil
unless ARGV[3] == "forever"
  start_date = DateTime.parse(ARGV[3]) if ARGV[3]
  end_date = DateTime.parse(ARGV[4]) if ARGV[4]

  last_execution = Utils::LocalStorage.new(path: "downloads/last_start_query_date-#{rails_env}.txt")
  if start_date.blank? && last_execution.exist?
    start_date = DateTime.parse(last_execution.content)
  end
end

puts "[START] check-data-presence/run.rb with datasets=#{ datasets.join(", ") }, start_date=#{ start_date }, end_date=#{ end_date }"

datasets_for_extraction = []
datasets.each do |dataset|
  puts "Checking #{ dataset } records presence..."
  dataset_query = Utils::OriginDataset.new(start_date: start_date, end_date: end_date, dataset: dataset, environment: rails_env, basic_auth_credentials: basic_auth_credentials)
  if (count = dataset_query.data_count) == 0
    if start_date.blank?
      puts "The dataset of #{ dataset } doesn't have any data"
    else
      puts "Dataset of #{ dataset } doesn't have data from #{ start_date }#{ end_date ? " to #{ end_date }" : "" }. Nothing to do."
    end
  else
    puts "Dataset of #{ dataset } contains #{ count || "unknown number of" } records#{ start_date ? " from #{ start_date }" : " of any date" }#{ end_date ? " to #{ end_date }" : "" }."
  end
  destination = Utils::LocalStorage.new(path: "downloads/datasets/#{ dataset }.csv")
  datasets_for_extraction << "--source-url #{ dataset_query.download_data_url } --output-file #{ destination.file_path } #{ dataset_query.auth_params }\n"
end

output = Utils::LocalStorage.new(content: datasets_for_extraction.join, path: "datasets_for_extraction")
start_query_date = Utils::LocalStorage.new(path: "output/start_query_date.txt", content: end_date || DateTime.now)
start_query_date.save
output.save
puts "Saved output in #{ output.file_path }"

puts "[END] check-data-presence/run.rb"
exit 0

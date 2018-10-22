#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

# Description:
#
#  Merges layout templates in differente locales into a single file
#
# Arguments:
#
#  - 0: Local storage path
#  - 1..n: Different locales of the layout that need to be retrieved
#
# Samples:
#
#   ruby $DEV_DIR/gobierto-etl-gencat/operations/import_custom_layout/merge_templates.rb $DEV_DIR/gobierto-etl-gencat/tmp es ca
#

STORAGE_DIR = ARGV[0]
LOCALES = ARGV[1..ARGV.length - 1]

if ARGV.length < 2
  raise "Incorrect number of arguments. Execute run.rb <local_storage_path> <locales>"
end

puts "[START] Merge templates with STORAGE_DIR=#{STORAGE_DIR}, LOCALES=#{LOCALES}"

OUTPUT_FILE_PATH = "#{STORAGE_DIR}/layouts_application.html.erb"
output_file_content = ""

def open_block(locale)
  "{% if current_locale == '#{locale}' %}"
end

def close_block
  "{% endif %}"
end

LOCALES.each do |locale|
  file_path = "#{STORAGE_DIR}/layouts_application_#{locale}.html.erb"

  puts "Processing #{file_path} ..."

  output_file_content << open_block(locale)
  output_file_content << File.read(file_path)
  output_file_content << close_block
end

File.write(OUTPUT_FILE_PATH, output_file_content)

puts "[END] Merge templates"

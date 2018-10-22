#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

# Description:
#
#  Updates the layouts/application.html.erb template for the specified Gobierto site.
#  Must be ran as a Gobierto runner.
#
# Arguments:
#
#  - 0: Domain of site where the transformed data has to be loaded
#  - 1: Template file location
#
# Samples:
#
#   cd $DEV_DIR/gobierto; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/custom_layout/load_template.rb madrid.gobierto.test $DEV_DIR/gobierto-etl-gencat/tmp/layouts_application.html.erb
#

puts "[START] custom_layout/load_template.rb"

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute load_template.rb <domain> <template_file_path>"
end

site = Site.find_by_domain ARGV[0]
template_file_path = ARGV[1]
template_content = File.read(template_file_path).to_s

template = ::GobiertoCore::Template.find_by(template_path: "layouts/application")
site_template = site.site_templates.where(template: template).first

if site_template
  puts "Template already exists - it'll be updated"
else
  puts "Template does not exist yet - it'll be created"
end

site_template_form = ::GobiertoAdmin::GobiertoCore::SiteTemplateForm.new(
  id: site_template&.id,
  site_id: site.id,
  markup: template_content,
  template_id: template.id
)

exit 1 unless site_template_form.save

puts "[END] custom_layout/load_template.rb"

exit 0

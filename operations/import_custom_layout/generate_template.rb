#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "open-uri"
require "nokogiri"

FAKE_ATTRIBUTE_VALUE = "REMOVE_ME"
FAKE_ATTRIBUTE_REGEX = /=\"#{FAKE_ATTRIBUTE_VALUE}\"/

# Description:
#
#  Takes as input the HTML template as downloaded from Gencat and converts it into an ERB,
#  with all our custom tags inserted. Must be run as a ruby script.
#
# Arguments:
#
#  - 0: Input file path
#  - 1: Output file path
#
# Samples:
#
#   ruby $DEV_DIR/gobierto-etl-gencat/operations/custom_layout/generate_template.rb $DEV_DIR/gobierto-etl-gencat/tmp/layouts_application.html $DEV_DIR/gobierto-etl-gencat/tmp/layouts_application.html.erb
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb <input_file_path> <output_file_path>"
end

input_file_path = ARGV[0]
output_file_path = ARGV[1]

puts "[START] custom_layout/generate_template.rb with input_file_path=#{input_file_path}, output_file_path=#{output_file_path}"

layout_page = Nokogiri::HTML(open(input_file_path))

# 1. Insert locale attribute:
#
#      <html lang="{% i18n_locale %}">

html_tag = layout_page.xpath("//html").first
html_tag["lang"] = "{% i18n_locale %}"

# 2. Insert gobierto_head right after the viewport meta tag:
#
#    <head>
#      <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
#        {% render_partial 'layouts/gobierto_head' %}

viewport_meta_tag = layout_page.xpath("//meta[@name='viewport']").first
text_node = Nokogiri::XML::Text.new(
  "{% render_partial 'layouts/gobierto_head' %}",
  layout_page
)
viewport_meta_tag.after(text_node)

# 3. Add custom attributes to body tag:
#
#      <body class="{% body_css_classes %}" {% yield body_attributes %}>

body_tag = layout_page.xpath("//body").first
body_tag["class"] = "{% body_css_classes %}"

body_tag["{% yield body_attributes %}"] = FAKE_ATTRIBUTE_VALUE

# 4. Add theme-gencat class to main article and add inner content
#
#     <section class="padding-xs padding-sm padding-md colorSectionOdd">
#       <article class="container fullcontainer-xs theme-gencat">
#         {% render_partial "user/shared/flash_messages" %}
#         {{ content_for_layout }}
#       </article>
#     </section>

main_article_tag = layout_page.xpath("//article").first
main_article_tag["class"] = "#{main_article_tag["class"]} theme-gencat"

text_node = Nokogiri::XML::Text.new(
  "{% render_partial 'user/shared/flash_messages' %}{{ content_for_layout }}",
  layout_page
)
main_article_tag.add_child(text_node)

# 5. Insert gobierto_footer right before body ending
#
#        {% render_partial 'layouts/gobierto_footer' %}
#      </body>
#    </html>

body_tag = layout_page.xpath("//body").first
text_node = Nokogiri::XML::Text.new("{% render_partial 'layouts/gobierto_footer' %}", layout_page)
body_tag.add_child(text_node)

layout_string = layout_page.to_s.gsub(FAKE_ATTRIBUTE_REGEX, "")

File.write(output_file_path, layout_string)

puts "[END] custom_layout/generate_template.rb"

exit 0

#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "open-uri"
require "nokogiri"

FAKE_ATTRIBUTE_VALUE = "REMOVE_ME"
FAKE_ATTRIBUTE_REGEX = /=\"#{FAKE_ATTRIBUTE_VALUE}\"/
ASSETS_HTTP_LOCATION = "http://governobert.gencat.cat"
ASSETS_HTTPS_LOCATION = "https://web.gencat.cat"
WEB_HTTP_LOCATION = "http://web.gencat.cat"
WEB_HTTPS_LOCATION = "https://web.gencat.cat"
SEARCH_BAD_CA="https://web.gencat.cat/ca/cercador/"
SEARCH_BAD_ES="https://web.gencat.cat/es/cercador/"
SEARCH_GOOD="https://web.gencat.cat/cercadorGencat"
GOBIERTO_STYLES_OVERRIDES_LOCATOR = "GOBIERTO_STYLES_OVERRIDES"
GOOGLE_TRANSLATE_SCRIPT_REGEX = /<script.*googleTranslateElementInit\"><\/script>/

def remove_default_page_header!(layout_page)
  header_tag = layout_page.xpath("//h1[@class='titulo-capcalera']").first
  header_tag.children.remove
  fixed_node = Nokogiri::XML::Node.new("span", layout_page)
  header_tag.add_child(fixed_node)
end

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

# Insert locale attribute:
#
#  <html lang="{% i18n_locale %}">

html_tag = layout_page.xpath("//html").first
html_tag["lang"] = "{% i18n_locale %}"

# Insert gobierto_head right after the viewport meta tag:
#
#   <head>
#     <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
#       {% render_partial 'layouts/gobierto_head' %}

viewport_meta_tag = layout_page.xpath("//meta[@name='viewport']").first
text_node = Nokogiri::XML::Text.new(
  "{% render_partial 'layouts/gobierto_head' %}",
  layout_page
)
viewport_meta_tag.after(text_node)

# Add custom attributes to body tag:
#
#   <body class="{% body_css_classes %}" {% yield body_attributes %}>

body_tag = layout_page.xpath("//body").first
body_tag["class"] = "{% body_css_classes %}"

body_tag["{% yield body_attributes %}"] = FAKE_ATTRIBUTE_VALUE

# Add theme-gencat class to main article and add inner content
#
#   <section class="padding-xs padding-sm padding-md colorSectionOdd">
#     <article class="container fullcontainer-xs theme-gencat">
#       {% render_partial "user/shared/flash_messages" %}
#       {{ content_for_layout }}
#     </article>
#   </section>

main_article_tag = layout_page.xpath("//article").first
main_article_tag["class"] = "#{main_article_tag["class"]} theme-gencat no-fullcontainer-xs"

text_node = Nokogiri::XML::Text.new(
  "{% render_partial 'user/shared/flash_messages' %}{{ content_for_layout }}",
  layout_page
)
main_article_tag.add_child(text_node)

# Insert gobierto_footer right before body ending
#
#      {% render_partial 'layouts/gobierto_footer' %}
#    </body>
#  </html>

body_tag = layout_page.xpath("//body").first
text_node = Nokogiri::XML::Text.new("{% render_partial 'layouts/gobierto_footer' %}", layout_page)
body_tag.add_child(text_node)

# Insert temporary tag to be replaced with the styles overries later on

styles_node = Nokogiri::XML::Text.new(GOBIERTO_STYLES_OVERRIDES_LOCATOR, layout_page)
head_tag = layout_page.xpath("//head").first
head_tag.add_child(styles_node)

# Insert temporary tag to be replaced with the locales switcher later on

tmp_text_node = Nokogiri::XML::Text.new("LOCALES_SWITCHER", layout_page)
if locales_swithcer_node = layout_page.xpath("//*[contains(@class, 'idioma')]").first
  locales_swithcer_node.children.remove
  locales_swithcer_node.add_child(tmp_text_node)
end

# Replace HTTP assets per HTTPs
layout_page.xpath("//script[contains(@src, '#{ASSETS_HTTP_LOCATION}')]").each do |node|
  node['src'] = node['src'].gsub(ASSETS_HTTP_LOCATION, ASSETS_HTTPS_LOCATION)
end

layout_page.xpath("//img[contains(@src, '#{ASSETS_HTTP_LOCATION}')]").each do |node|
  node['src'] = node['src'].gsub(ASSETS_HTTP_LOCATION, ASSETS_HTTPS_LOCATION)
end

layout_page.xpath("//link[contains(@href, '#{ASSETS_HTTP_LOCATION}')]").each do |node|
  node['href'] = node['href'].gsub(ASSETS_HTTP_LOCATION, ASSETS_HTTPS_LOCATION)
end

# Remove default page header
remove_default_page_header!(layout_page)

# Remove placeholder node attribute values
layout_string = layout_page.to_s.gsub(FAKE_ATTRIBUTE_REGEX, "")

# Fix some
layout_string.gsub!(WEB_HTTP_LOCATION, WEB_HTTPS_LOCATION)
layout_string.gsub!(SEARCH_BAD_CA, SEARCH_GOOD)
layout_string.gsub!(SEARCH_BAD_ES, SEARCH_GOOD)

# Replace custom styles locator with real content

styles_content = File.read("#{File.dirname(__FILE__)}/gobierto_styles_overrides.html")
layout_string.gsub!(GOBIERTO_STYLES_OVERRIDES_LOCATOR, styles_content)

# Replace locale switchers locator with real content

locales_content = File.read("#{File.dirname(__FILE__)}/locales_switcher.html")
layout_string.gsub!("LOCALES_SWITCHER", locales_content)

# Remove Google Translate script

layout_string.gsub!(GOOGLE_TRANSLATE_SCRIPT_REGEX, "")

# Write output file

File.write(output_file_path, layout_string)

puts "[END] custom_layout/generate_template.rb"

exit 0
